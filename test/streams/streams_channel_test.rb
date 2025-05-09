require "test_helper"
require "action_cable"

class Superglue::StreamsChannelTest < ActionCable::Channel::TestCase
  # include Superglue::Streams::ActionHelper
  include ActiveJob::TestHelper

  test "verified stream name" do
    assert_equal "stream",
      Superglue::StreamsChannel.verified_stream_name(Superglue::StreamsChannel.signed_stream_name("stream"))
  end

  def render_message(options)
    ApplicationController.render(formats: [:json], **options)
  end

  # test 'broadcasting remove now' do
  #   assert_broadcast_on 'stream', turbo_stream_action_tag('remove', target: 'message_1') do
  #     Superglue::StreamsChannel.broadcast_remove_to 'stream', target: 'message_1'
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('remove', targets: '.message') do
  #     Superglue::StreamsChannel.broadcast_remove_to 'stream', targets: '.message'
  #   end
  # end

  # test 'broadcasting remove now with record' do
  #   assert_broadcast_on 'stream', turbo_stream_action_tag('remove', target: 'message_1') do
  #     Superglue::StreamsChannel.broadcast_remove_to 'stream', target: Message.new(id: 1, content: 'hello!')
  #   end
  # end

  test "broadcasting replace now" do
    locals = {message: "hello!"}
    rendering = {partial: "messages/message", locals: locals}

    expected = rendering.clone.merge(
      layout: "superglue/layouts/fragment",
      locals: locals.merge({
        broadcast_targets: ["message_1"],
        broadcast_action: "replace",
        broadcast_options: {}
      })
    )

    assert_broadcast_on "stream", render_message(expected) do
      Superglue::StreamsChannel.broadcast_replace_to "stream", target: "message_1", **rendering
    end

    assert_broadcast_on "stream", render_message(expected) do
      Superglue::StreamsChannel.broadcast_replace_to "stream", targets: ["message_1"], **rendering
    end
  end

  # test 'broadcasting update now' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('update', target: 'message_1', template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_update_to 'stream', target: 'message_1', **options
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('update', targets: '.message', template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_update_to 'stream', targets: '.message', **options
  #   end
  # end

  test "broadcasting append now" do
    locals = {message: "hello!"}
    rendering = {partial: "messages/message", locals: locals}

    expected = rendering.clone.merge(
      layout: "superglue/layouts/fragment",
      locals: locals.merge({
        broadcast_targets: ["messages"],
        broadcast_action: "append",
        broadcast_options: {}
      })
    )

    assert_broadcast_on "stream", render_message(expected) do
      Superglue::StreamsChannel.broadcast_append_to "stream", target: "messages", **rendering
    end

    assert_broadcast_on "stream", render_message(expected) do
      Superglue::StreamsChannel.broadcast_append_to "stream", targets: ["messages"], **rendering
    end
  end

  # test 'broadcasting append now with empty template' do
  #   assert_broadcast_on 'stream',
  #                       %(<turbo-stream action="append" target="message_1"><template></template></turbo-stream>) do
  #     Superglue::StreamsChannel.broadcast_append_to 'stream', target: 'message_1', content: ''
  #   end
  # end

  # test 'broadcasting prepend now' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('prepend', target: 'messages', template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_prepend_to 'stream', target: 'messages', **options
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('prepend', targets: '.message', template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_prepend_to 'stream', targets: '.message', **options
  #   end
  # end

  # test 'broadcasting action now' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('prepend', target: 'messages', template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_action_to 'stream', action: 'prepend', target: 'messages', **options
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('prepend', targets: '.message', template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_action_to 'stream', action: 'prepend', targets: '.message', **options
  #   end

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('prepend', targets: '.message', template: '<span>test</span>') do
  #     Superglue::StreamsChannel.broadcast_action_to 'stream', action: 'prepend', targets: '.message',
  #                                                             content: '<span>test</span>'
  #   end

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('prepend', targets: '.message', template: '<span>test</span>') do
  #     Superglue::StreamsChannel.broadcast_action_to 'stream', action: 'prepend', targets: '.message',
  #                                                             html: '<span>test</span>'
  #   end
  # end

  # test 'broadcasting replace later' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('replace', target: 'message_1', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_replace_later_to \
  #         'stream', target: 'message_1', **options
  #     end
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('replace', targets: '.message', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_replace_later_to \
  #         'stream', targets: '.message', **options
  #     end
  #   end
  # end

  # test 'broadcasting update later' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('update', target: 'message_1', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_update_later_to \
  #         'stream', target: 'message_1', **options
  #     end
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('update', targets: '.message', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_update_later_to \
  #         'stream', targets: '.message', **options
  #     end
  #   end
  # end

  # test 'broadcasting append later' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('append', target: 'messages', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_append_later_to \
  #         'stream', target: 'messages', **options
  #     end
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('append', targets: '.message', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_append_later_to \
  #         'stream', targets: '.message', **options
  #     end
  #   end
  # end

  # test 'broadcasting prepend later' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('prepend', target: 'messages', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_prepend_later_to \
  #         'stream', target: 'messages', **options
  #     end
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('prepend', targets: '.message', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_prepend_later_to \
  #         'stream', targets: '.message', **options
  #     end
  #   end
  # end

  # test 'broadcasting refresh later' do
  #   assert_broadcast_on 'stream', turbo_stream_refresh_tag do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_refresh_later_to 'stream'
  #       Superglue::StreamsChannel.refresh_debouncer_for('stream').wait
  #     end
  #   end

  #   Turbo.current_request_id = '123'
  #   assert_broadcast_on 'stream', turbo_stream_refresh_tag(request_id: '123') do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_refresh_later_to 'stream'
  #       Superglue::StreamsChannel.refresh_debouncer_for('stream', request_id: '123').wait
  #     end
  #   end
  # end

  # test 'broadcasting refresh later is debounced' do
  #   assert_broadcast_on 'stream', turbo_stream_refresh_tag do
  #     assert_broadcasts('stream', 1) do
  #       perform_enqueued_jobs do
  #         Superglue::StreamsChannel.broadcast_refresh_later_to 'stream'

  #         Superglue::StreamsChannel.refresh_debouncer_for('stream').wait
  #       end
  #     end
  #   end
  # end

  # test 'broadcasting refresh later is debounced considering the current request id' do
  #   assert_broadcasts('stream', 2) do
  #     perform_enqueued_jobs do
  #       assert_broadcast_on 'stream', turbo_stream_refresh_tag("request-id": '123') do
  #         assert_broadcast_on 'stream', turbo_stream_refresh_tag("request-id": '456') do
  #           Turbo.current_request_id = '123'
  #           3.times { Superglue::StreamsChannel.broadcast_refresh_later_to 'stream' }

  #           Turbo.current_request_id = '456'
  #           3.times { Superglue::StreamsChannel.broadcast_refresh_later_to 'stream' }

  #           Superglue::StreamsChannel.refresh_debouncer_for('stream', request_id: '123').wait
  #           Superglue::StreamsChannel.refresh_debouncer_for('stream', request_id: '456').wait
  #         end
  #       end
  #     end
  #   end
  # end

  # test 'broadcasting action later' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('prepend', target: 'messages', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_action_later_to \
  #         'stream', action: 'prepend', target: 'messages', **options
  #     end
  #   end

  #   assert_broadcast_on 'stream', turbo_stream_action_tag('prepend', targets: '.message', template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_action_later_to \
  #         'stream', action: 'prepend', targets: '.message', **options
  #     end
  #   end
  # end

  # test 'broadcasting action later with ActiveModel array target' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   message = Message.new(id: 42)
  #   target = [message, 'opt']
  #   expected_target = 'opt_message_42'

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('prepend', target: expected_target, template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_action_later_to \
  #         'stream', action: 'prepend', target: target, **options
  #     end
  #   end
  # end

  # test 'broadcasting action later with multiple ActiveModel targets' do
  #   options = { partial: 'messages/message', locals: { message: 'hello!' } }

  #   one = Message.new(id: 1)
  #   targets = [one, 'messages']
  #   expected_targets = '#messages_message_1'

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('prepend', targets: expected_targets, template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_action_later_to \
  #         'stream', action: 'prepend', targets: targets, **options
  #     end
  #   end
  # end

  # test 'broadcasting render now' do
  #   assert_broadcast_on 'stream', turbo_stream_action_tag('replace', target: 'message_1', template: 'Goodbye!') do
  #     Superglue::StreamsChannel.broadcast_render_to 'stream', partial: 'messages/message'
  #   end
  # end

  # test 'broadcasting render later' do
  #   assert_broadcast_on 'stream', turbo_stream_action_tag('replace', target: 'message_1', template: 'Goodbye!') do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_render_later_to 'stream', partial: 'messages/message'
  #     end
  #   end
  # end

  # test 'broadcasting direct update now' do
  #   assert_broadcast_on 'stream', %(direct) do
  #     Superglue::StreamsChannel.broadcast_stream_to 'stream', content: 'direct'
  #   end
  # end

  # test 'broadcasting actions with method morph now' do
  #   options = { attributes: { method: :morph }, partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('replace', target: 'message_1', method: :morph,
  #                                                          template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_replace_to 'stream', target: 'message_1', **options
  #   end

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('replace', targets: '.message', method: :morph,
  #                                                          template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_replace_to 'stream', targets: '.message', **options
  #   end

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('update', target: 'message_1', method: :morph,
  #                                                         template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_update_to 'stream', target: 'message_1', **options
  #   end

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('update', targets: '.message', method: :morph,
  #                                                         template: render(options)) do
  #     Superglue::StreamsChannel.broadcast_update_to 'stream', targets: '.message', **options
  #   end
  # end

  # test 'broadcasting actions with method morph later' do
  #   options = { attributes: { method: :morph }, partial: 'messages/message', locals: { message: 'hello!' } }

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('replace', target: 'message_1', method: :morph,
  #                                                          template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_replace_later_to \
  #         'stream', target: 'message_1', **options
  #     end
  #   end

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('replace', targets: '.message', method: :morph,
  #                                                          template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_replace_later_to \
  #         'stream', targets: '.message', **options
  #     end
  #   end

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('update', target: 'message_1', method: :morph,
  #                                                         template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_update_later_to \
  #         'stream', target: 'message_1', **options
  #     end
  #   end

  #   assert_broadcast_on 'stream',
  #                       turbo_stream_action_tag('update', targets: '.message', method: :morph,
  #                                                         template: render(options)) do
  #     perform_enqueued_jobs do
  #       Superglue::StreamsChannel.broadcast_update_later_to \
  #         'stream', targets: '.message', **options
  #     end
  #   end
  # end
end
