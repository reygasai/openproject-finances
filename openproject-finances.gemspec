# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "open_project/finances/version"

Gem::Specification.new do |s|
  s.name        = "openproject-finances"
  s.version     = OpenProject::Finances::VERSION
  s.authors     = ["reygasai"]
  s.summary     = "OpenProject Finances — project income/expense ledger with CBR rates"
  s.description = "Project-level finance entries with multi-currency support and Central Bank of Russia exchange rates."
  s.license     = "GPL-3.0-only"
  s.homepage    = "https://github.com/reygasai/openproject-finances"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w[README.md CHANGELOG.md LICENSE]

  s.required_ruby_version = ">= 3.4.0"
  s.metadata["rubygems_mfa_required"] = "true"
  s.metadata["source_code_uri"] = "https://github.com/reygasai/openproject-finances"
  s.metadata["changelog_uri"] = "https://github.com/reygasai/openproject-finances/blob/main/CHANGELOG.md"
end
