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
