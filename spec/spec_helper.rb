# frozen_string_literal: true

openproject_root = ENV.fetch("OPENPROJECT_ROOT", File.expand_path("../../..", __dir__))
require File.join(openproject_root, "spec/spec_helper")

Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }
