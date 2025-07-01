# Configure Rails Environment
require "dotenv/load"

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

def render_props(action, partial:, locals: {}, fragment: nil, fragments: nil, options: {})
  fragments = fragment ? [fragment] : fragments
  if options[:save_as]
    options[:saveAs] = options.delete(:save_as)
  end

  if locals[:json]
    json = locals.delete(:json)
    render({
      partial: "superglue/layouts/stream_message",
      locals: locals.merge({
        broadcast_json: json,
        broadcast_fragment_keys: fragments,
        broadcast_action: action,
        broadcast_options: options
      })
    })

  else
    render({
      partial: partial,
      layout: "superglue/layouts/stream_message",
      locals: locals.merge({
        broadcast_fragment_keys: fragments,
        broadcast_action: action,
        broadcast_options: options
      })
    })
  end
end
