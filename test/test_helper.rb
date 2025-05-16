# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"

ActionCable.server.config.logger = Logger.new(STDOUT) if ENV["VERBOSE"]

module ActionViewTestCaseExtensions
  delegate :render, to: ApplicationController
end

class ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    Superglue.current_request_id = nil
  end
end

class ActionDispatch::IntegrationTest
  include ActionViewTestCaseExtensions
end

class ActionCable::Channel::TestCase
  include ActionViewTestCaseExtensions
end

def render_props(action, partial:, locals: {}, target: nil, targets: nil, options: {})
  targets = target ? [target] : targets

  render({
    partial: partial,
    layout: "superglue/layouts/fragment",
    locals: locals.merge({
      broadcast_targets: targets,
      broadcast_action: action,
      broadcast_options: options
    })
  })
end
