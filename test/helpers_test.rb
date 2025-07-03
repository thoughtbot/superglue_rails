require "test_helper"

class HelpersTest < ActiveSupport::TestCase
  include Superglue::Helpers

  test "clean_props_at returns nil if qry is nil" do
    qry = nil

    assert_nil param_to_dig_path(qry)
  end

  test "clean_props_at returns a refined qry" do
    qry = "foo...bar/?)()-"

    assert_equal param_to_dig_path(qry), ["foo", "bar"]
  end
end

class StreamsHelperTest < ActiveSupport::TestCase
  include Superglue::StreamsHelper

  test "fragment_id returns dom_id for objects with to_key" do
    message = Message.new(id: 1, content: "test")

    assert_equal "message_1", fragment_id(message)
  end

  test "fragment_id returns broadcast_fragment_default for classes that define it" do
    klass = Class.new do
      def self.broadcast_fragment_default
        "custom_fragment"
      end
    end

    assert_equal "custom_fragment", fragment_id(klass)
  end

  test "fragment_id returns string representation for strings" do
    assert_equal "my_fragment", fragment_id("my_fragment")
  end

  test "fragment_id returns string representation for symbols" do
    assert_equal "my_symbol", fragment_id(:my_symbol)
  end

  test "fragment_id returns string representation for numbers" do
    assert_equal "123", fragment_id(123)
  end

  test "fragment_id prioritizes to_key over broadcast_fragment_default" do
    message = Message.new(id: 42, content: "test")

    def message.broadcast_fragment_default
      "should_not_be_used"
    end

    assert_equal "message_42", fragment_id(message)
  end

  test "fragment_id handles nil values" do
    assert_equal "", fragment_id(nil)
  end

  test "stream_from_props returns attributes with signed stream name" do
    message = Message.new(id: 1)
    result = stream_from_props(message)

    assert_equal "Superglue::StreamsChannel", result[:channel]
    assert result[:signed_stream_name].present?
    assert_kind_of String, result[:signed_stream_name]
  end

  test "stream_from_props accepts custom channel" do
    message = Message.new(id: 1)
    result = stream_from_props(message, channel: "CustomChannel")

    assert_equal "CustomChannel", result[:channel]
  end

  test "stream_from_props accepts symbol channel" do
    message = Message.new(id: 1)
    result = stream_from_props(message, channel: :MyChannel)

    assert_equal "MyChannel", result[:channel]
  end

  test "stream_from_props handles multiple streamables" do
    message1 = Message.new(id: 1)
    message2 = Message.new(id: 2)
    result = stream_from_props(message1, message2)

    assert_equal "Superglue::StreamsChannel", result[:channel]
    assert result[:signed_stream_name].present?
  end

  test "stream_from_props handles string streamables" do
    result = stream_from_props("my_stream")

    assert_equal "Superglue::StreamsChannel", result[:channel]
    assert result[:signed_stream_name].present?
  end

  test "stream_from_props raises error for blank streamables" do
    assert_raises ArgumentError, "streamables can't be blank" do
      stream_from_props
    end
  end

  test "stream_from_props raises error for all blank streamables" do
    assert_raises ArgumentError, "streamables can't be blank" do
      stream_from_props(nil, "", "  ")
    end
  end

  test "stream_from_props filters out blank streamables" do
    message = Message.new(id: 1)
    result = stream_from_props(message, nil, "", "  ")

    assert_equal "Superglue::StreamsChannel", result[:channel]
    assert result[:signed_stream_name].present?
  end

  test "stream_from_props passes through additional attributes" do
    message = Message.new(id: 1)
    result = stream_from_props(message, foo: "bar", class: "my-class")

    assert_equal "Superglue::StreamsChannel", result[:channel]
    assert_equal "bar", result[:foo]
    assert_equal "my-class", result[:class]
    assert result[:signed_stream_name].present?
  end
end

class BroadcastViewHelpersTest < ActiveSupport::TestCase
  include ActionViewTestCaseExtensions
  include Superglue::StreamsHelper

  setup do
    @message = Message.new(id: 1, content: "Hello!")
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.response = ActionDispatch::TestResponse.new
    controller.prepend_view_path "test/views"
    @controller = controller
  end

  def with_json_template(template_content)
    template_dir = File.expand_path("../views/application", __FILE__)
    template_path = File.join(template_dir, "test_broadcast.json.props")
    File.delete(template_path) if File.exist?(template_path)
    File.write(template_path, template_content)

    @controller.view_paths.each(&:clear_cache)

    yield
  ensure
    File.delete(template_path) if File.exist?(template_path)
  end

  test "broadcast_prepend_props with model generates expected JSON structure" do
    template_content = <<~PROPS
      json.array! do
        broadcast_prepend_props(model: @message)
      end
    PROPS

    with_json_template(template_content) do
      message = Message.new(id: 1, content: "Hello!")
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message:}).chomp

      assert_equal(result, [{
        fragmentKeys: ["messages"],
        action: "prepend",
        options: {},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_prepend_props with save_as option" do
    template_content = <<~PROPS
      json.array! do
        broadcast_prepend_props(model: @message, save_as: "custom_fragment")
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["messages"],
        action: "prepend",
        options: {saveAs: "custom_fragment"},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_append_props with model generates expected JSON structure" do
    template_content = <<~PROPS
      json.array! do
        broadcast_append_props(model: @message)
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["messages"],
        action: "append",
        options: {},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_append_props with save_as option using model" do
    template_content = <<~PROPS
      json.array! do
        broadcast_append_props(model: @message, save_as: @message)
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["messages"],
        action: "append",
        options: {saveAs: "message_1"},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_save_props with model" do
    template_content = <<~PROPS
      json.array! do
        broadcast_save_props(model: @message)
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["messages"],
        action: "save",
        options: {},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_action_props with custom action and fragment" do
    template_content = <<~PROPS
      json.array! do
        broadcast_action_props(action: "replace", model: @message, fragment: "custom_frag")
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["custom_frag"],
        action: "replace",
        options: {},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_action_props with partial and no model" do
    template_content = <<~PROPS
      json.array! do
        broadcast_action_props(action: "update", partial: "messages/message", fragment: "msg_123", locals: {message: @message})
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["msg_123"],
        action: "update",
        options: {},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_action_props raises error when no partial can be determined" do
    template_content = <<~PROPS
      json.array! do
        broadcast_action_props(action: "save", fragment: "some_fragment")
      end
    PROPS

    with_json_template(template_content) do
      assert_raises ActionView::Template::Error, "A partial is needed to render a stream" do
        @controller.render_to_string("test_broadcast", format: :json, layout: false)
      end
    end
  end

  test "broadcast methods pass through custom options" do
    template_content = <<~PROPS
      json.array! do
        broadcast_prepend_props(model: @message, options: {target: "#messages", position: "afterbegin"})
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["messages"],
        action: "prepend",
        options: {target: "#messages", position: "afterbegin"},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast methods with custom rendering options" do
    template_content = <<~PROPS
      json.array! do
        broadcast_append_props(model: @message, locals: {custom_var: "custom_value"})
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["messages"],
        action: "append",
        options: {},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_action_props uses model.broadcast_fragment_default when no fragment provided" do
    custom_model = Message.new(id: 1, content: "Custom")
    def custom_model.broadcast_fragment_default
      "custom_messages"
    end

    template_content = <<~PROPS
      json.array! do
        broadcast_action_props(action: "prepend", model: @custom_model)
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {custom_model:}).chomp

      assert_equal(result, [{
        fragmentKeys: ["custom_messages"],
        action: "prepend",
        options: {},
        data: {
          body: "Custom"
        }
      }].to_json)
    end
  end

  test "broadcast_action_props explicit fragment overrides broadcast_fragment_default" do
    template_content = <<~PROPS
      json.array! do
        broadcast_action_props(action: "append", model: @message, fragment: "explicit_fragment")
      end
    PROPS

    with_json_template(template_content) do
      result = @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {message: @message}).chomp

      assert_equal(result, [{
        fragmentKeys: ["explicit_fragment"],
        action: "append",
        options: {},
        data: {
          body: "Hello!"
        }
      }].to_json)
    end
  end

  test "broadcast_action_props handles model without broadcast_fragment_default method" do
    # Create a plain object that doesn't have broadcast_fragment_default
    plain_model = OpenStruct.new(id: 1, content: "Plain", model_name: OpenStruct.new(element: "plain"))
    def plain_model.to_partial_path
      "messages/message"
    end

    template_content = <<~PROPS
      json.array! do
        broadcast_action_props(action: "save", model: @plain_model)
      end
    PROPS

    with_json_template(template_content) do
      assert_raises NoMethodError do
        @controller.render_to_string("test_broadcast", format: :json, layout: false, assigns: {plain_model:})
      end
    end
  end
end
