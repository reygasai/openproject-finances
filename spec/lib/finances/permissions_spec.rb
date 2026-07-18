# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenProject::AccessControl, "Finances module permissions" do # rubocop:disable RSpec/SpecFilePathFormat
  {
    create_finance_entries: :view_finance_entries,
    edit_finance_entries: :view_finance_entries,
    delete_finance_entries: :view_finance_entries
  }.each do |permission, dependency|
    describe permission.to_s do
      subject { described_class.permission(permission) }

      it "depends on #{dependency}" do
        expect(subject.dependencies).to contain_exactly(dependency)
      end
    end
  end
end
