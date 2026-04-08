# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

require "test_helper"
require "action_cable"

class Superglue::StreamsChannelTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  setup { @message = Message.create(content: "Hello!") }

  test "verified stream name" do
    assert_equal "stream",
      Superglue::StreamsChannel.verified_stream_name(Superglue::StreamsChannel.signed_stream_name("stream"))
  end

  def rendering
    {partial: "messages/message", locals: {message: @message}}
  end

  test "broadcasting save now" do
    assert_broadcast_on "stream", render_props("save", target: "message_1", **rendering) do
      Superglue::StreamsChannel.broadcast_save_to "stream", target: "message_1", **rendering
    end

    assert_broadcast_on "stream", render_props("save", targets: ["message_1"], **rendering) do
      Superglue::StreamsChannel.broadcast_save_to "stream", targets: ["message_1"], **rendering
    end
  end

  test "broadcasting append now" do
    assert_broadcast_on "stream", render_props("append", target: "messages", **rendering) do
      Superglue::StreamsChannel.broadcast_append_to "stream", target: "messages", **rendering
    end

    assert_broadcast_on "stream", render_props("append", targets: ["messages"], **rendering) do
      Superglue::StreamsChannel.broadcast_append_to "stream", targets: ["messages"], **rendering
    end
  end

  test "broadcasting prepend now" do
    assert_broadcast_on "stream", render_props("prepend", target: "messages", **rendering) do
      Superglue::StreamsChannel.broadcast_prepend_to "stream", target: "messages", **rendering
    end

    assert_broadcast_on "stream", render_props("prepend", targets: ["messages"], **rendering) do
      Superglue::StreamsChannel.broadcast_prepend_to "stream", targets: ["messages"], **rendering
    end
  end

  test "broadcasting action now" do
    assert_broadcast_on "stream", render_props("prepend", target: "messages", **rendering) do
      Superglue::StreamsChannel.broadcast_action_to "stream", action: "prepend", target: "messages", **rendering
    end

    assert_broadcast_on "stream", render_props("prepend", targets: ["messages"], **rendering) do
      Superglue::StreamsChannel.broadcast_action_to "stream", action: "prepend", targets: ["messages"], **rendering
    end

    assert_broadcast_on "stream",
      render_props("prepend", targets: ["messages"], **rendering.merge({locals: {json: {body: "test"}}})) do
      Superglue::StreamsChannel.broadcast_action_to "stream", action: "prepend", targets: ["messages"],
        json: {body: "test"}, **rendering
    end
  end

  test "broadcasting save later" do
    assert_broadcast_on "stream", render_props("save", target: "message_1", **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_save_later_to "stream", target: "message_1", **rendering
      end
    end

    assert_broadcast_on "stream", render_props("save", targets: ["message_1"], **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_save_later_to "stream", targets: ["message_1"], **rendering
      end
    end
  end

  test "broadcasting append later" do
    assert_broadcast_on "stream", render_props("append", target: "messages", **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_append_later_to "stream", target: "messages", **rendering
      end
    end

    assert_broadcast_on "stream", render_props("append", targets: ["messages"], **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_append_later_to "stream", targets: ["messages"], **rendering
      end
    end
  end

  test "broadcasting prepend later" do
    assert_broadcast_on "stream", render_props("prepend", target: "messages", **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_prepend_later_to "stream", target: "messages", **rendering
      end
    end

    assert_broadcast_on "stream", render_props("prepend", targets: ["messages"], **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_prepend_later_to "stream", targets: ["messages"], **rendering
      end
    end
  end

  test "broadcasting action later" do
    assert_broadcast_on "stream", render_props("prepend", target: "messages", **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_action_later_to \
          "stream", action: "prepend", target: "messages", **rendering
      end
    end

    assert_broadcast_on "stream", render_props("prepend", targets: ["messages"], **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_action_later_to \
          "stream", action: "prepend", targets: ["messages"], **rendering
      end
    end
  end

  test "broadcasting action later with ActiveModel array target" do
    message = Message.new(id: 42)
    target = [message, "opt"]

    assert_broadcast_on "stream", render_props("prepend", target: "opt_message_42", **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_action_later_to \
          "stream", action: "prepend", target: target, **rendering
      end
    end
  end

  test "broadcasting action later with multiple ActiveModel targets" do
    one = Message.new(id: 1)
    two = Message.new(id: 2)
    targets = [[one, "msg"], [two, "msg"]]

    assert_broadcast_on "stream", render_props("prepend", targets: ["msg_message_1", "msg_message_2"], **rendering) do
      perform_enqueued_jobs do
        Superglue::StreamsChannel.broadcast_action_later_to \
          "stream", action: "prepend", targets: targets, **rendering
      end
    end
  end
end
