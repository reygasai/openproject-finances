# frozen_string_literal: true

Rails.application.routes.draw do
  resources :projects, only: [] do
    resources :finance_entries, only: %i[index new create]

    # Named explicitly so Filter::FilterComponent can call
    # project_finance_entries_filters_path(project_id: ...).
    get "finance_entries/filters",
        to: "finance_entries/filters#show",
        as: :finance_entries_filters
  end

  resources :finance_entries, only: %i[edit update destroy] do
    member do
      get :destroy_dialog
      get :history
    end
  end
end
