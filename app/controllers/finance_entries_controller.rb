# frozen_string_literal: true

class FinanceEntriesController < ApplicationController
  include OpTurbo::ComponentStream
  include PaginationHelper

  helper Finances::AmountHelper

  before_action :find_project_by_project_id, only: %i[index new create]
  before_action :find_finance_entry, only: %i[edit update destroy destroy_dialog history]
  before_action :authorize

  def index
    @query = build_query

    respond_to do |format|
      format.html do
        load_index_data
        return if performed?
      end
      format.turbo_stream do
        load_index_data
        return if performed?

        replace_via_turbo_stream(
          component: Finances::ResultsComponent.new(
            entries: @finance_entries,
            totals: @totals,
            project: @project
          )
        )
        update_via_turbo_stream(
          component: Finances::SubHeaderComponent.new(
            query: @query,
            project: @project,
            params:
          )
        )
        respond_with_turbo_streams
      end
      format.csv { send_export(:csv) }
      format.xls { send_export(:xls) }
    end
  end

  def new
    @finance_entry = build_entry
    respond_with_entry_dialog(
      Finances::EntryDialogComponent.new(entry: @finance_entry, project: @project)
    )
  end

  def create
    call = FinanceEntries::CreateService
             .new(user: User.current)
             .call(service_attributes.merge(project: @project))

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to project_finance_entries_path(@project)
    else
      @finance_entry = call.result
      respond_with_entry_dialog(
        Finances::EntryDialogComponent.new(entry: @finance_entry, project: @project)
      )
    end
  end

  def edit
    respond_with_entry_dialog(
      Finances::EntryDialogComponent.new(entry: @finance_entry, project: @finance_entry.project)
    )
  end

  def update
    call = FinanceEntries::UpdateService
             .new(user: User.current, model: @finance_entry)
             .call(service_attributes)

    if call.success?
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_finance_entries_path(@finance_entry.project)
    else
      respond_with_entry_dialog(
        Finances::EntryDialogComponent.new(entry: call.result, project: call.result.project)
      )
    end
  end

  def destroy_dialog
    respond_with_entry_dialog(Finances::DestroyDialogComponent.new(entry: @finance_entry))
  end

  def destroy
    project = @finance_entry.project
    call = FinanceEntries::DeleteService
             .new(user: User.current, model: @finance_entry)
             .call

    flash[call.success? ? :notice : :error] =
      call.success? ? I18n.t(:notice_successful_delete) : call.message
    redirect_to project_finance_entries_path(project)
  end

  def history
    respond_with_entry_dialog(Finances::HistoryDialogComponent.new(entry: @finance_entry))
  end

  private

  # Dialogs are turbo-stream only; HTML (direct open / missing data-turbo-stream)
  # falls back to the project index instead of 406.
  def respond_with_entry_dialog(dialog_component)
    respond_with_dialog(dialog_component) do |format|
      format.html { redirect_to project_finance_entries_path(@project) }
    end
  end


  def load_index_data
    @finance_entries = export_scope.paginate(page: page_param, per_page: per_page_param)
    # Primer pagination raises when current_page > total_pages (e.g. stale ?page=2).
    return redirect_to_safe_finance_entries_page if @finance_entries.out_of_bounds?

    @totals = FinanceEntries::Totals.new(@query.results).call
  end

  def redirect_to_safe_finance_entries_page
    safe_page = [@finance_entries.total_pages, 1].max
    redirect_params = request.query_parameters.except("format")

    redirect_params =
      if safe_page <= 1
        redirect_params.except("page")
      else
        redirect_params.merge("page" => safe_page)
      end

    redirect_to project_finance_entries_path(@project, redirect_params)
  end

  def send_export(format)
    export = FinanceEntries::Export.new(entries: export_scope.to_a, project: @project)

    case format
    when :csv
      send_data(
        export.to_csv,
        type: "text/csv; header=present",
        filename: export.filename("csv")
      )
    when :xls
      send_data(
        export.to_xls,
        type: "application/vnd.ms-excel",
        filename: export.filename("xls")
      )
    end
  end

  def export_scope
    @query.results
      .includes(:author, :user_participants, :external_participants, :work_packages)
  end

  def find_finance_entry
    @finance_entry = FinanceEntry.visible.find(params[:id])
    @project = @finance_entry.project
  end

  def build_entry
    FinanceEntries::SetAttributesService
      .new(user: User.current, model: FinanceEntry.new, contract_class: EmptyContract)
      .call(project: @project)
      .result
  end

  def build_query
    query = ParamsToQueryService
              .new(FinanceEntry, User.current, query_class: Queries::FinanceEntries::FinanceEntryQuery)
              .call(params)
    query.where("project_id", "=", [@project.id.to_s])
    apply_entry_orders(query)
  end

  # Default: newest entry_date first. Secondary id keeps pagination stable.
  def apply_entry_orders(query)
    if query.orders.empty?
      query.order(entry_date: :desc, id: :desc)
    elsif query.orders.none? { |order| order.attribute.to_s == "id" }
      query.order(id: query.orders.first.direction)
    end

    query
  end

  def finance_entry_params
    params.require(:finance_entry).permit(
      :amount,
      :currency,
      :entry_date,
      :description,
      :external_participant_names_input,
      user_participant_ids: [],
      work_package_ids: []
    )
  end

  # Association keys are applied only when present so an untouched/omitted
  # multi-autocompleter does not wipe existing participants or work packages.
  # Cleared selections still submit [""] via the autocompleter hidden fields.
  def service_attributes
    permitted = finance_entry_params
    attrs = {
      amount: permitted[:amount],
      currency: permitted[:currency],
      entry_date: permitted[:entry_date],
      description: permitted[:description]
    }

    if permitted.key?(:user_participant_ids)
      attrs[:user_participant_ids] = Array(permitted[:user_participant_ids]).compact_blank
    end

    if permitted.key?(:work_package_ids)
      attrs[:work_package_ids] = Array(permitted[:work_package_ids]).compact_blank
    end

    if permitted.key?(:external_participant_names_input)
      attrs[:external_participant_names] =
        permitted[:external_participant_names_input].to_s.split(",").map(&:strip).compact_blank
    end

    attrs
  end
end
