require "application_system_test_case"

class BroadcastsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper
  extend Superglue::Streams::StreamName

  test "Message broadcasts Turbo Streams" do
    visit messages_path

    assert_broadcasts_text "Message 1", to: :messages do |text, fragment|
      Message.create(content: text).broadcast_append_to(fragment)
    end
  end

  test "Message broadcasts with html: render option" do
    visit messages_path

    assert_broadcasts_text "Hello, with json: option", to: :messages do |text, fragment|
      Message.create(content: "Ignored").broadcast_append_to(fragment, json: {body: text})
    end
  end

  test "Message broadcasts with extra attributes to turbo stream tag" do
    visit messages_path

    body = "Message 1"
    within(:element, id: "messages") { assert_no_text body }
    within(:element, id: "spotlight") { assert_no_text body }

    # todo: change options[:fragment] to option[:save_as]
    # when the js library is updated
    Message.create(content: body).broadcast_action_to("messages", action: :append, options: {fragment: "message-1"})

    within(:element, id: "messages") { assert_text body }
    within(:element, id: "spotlight") { assert_text body }
  end

  test "Message broadcasts later with extra attributes to turbo stream tag" do
    visit messages_path

    perform_enqueued_jobs do
      body = "Message 1"
      within(:element, id: "messages") { assert_no_text body }
      within(:element, id: "spotlight") { assert_no_text body }

      # todo: change options[:fragment] to option[:save_as]
      # when the js library is updated
      Message.create(content: body).broadcast_action_later_to("messages", action: :append, options: {fragment: "message-1"})

      within(:element, id: "messages") { assert_text body }
      within(:element, id: "spotlight") { assert_text body }
    end
  end

  test "Users::Profile broadcasts Turbo Streams" do
    visit users_profiles_path

    assert_broadcasts_text "Profile 1", to: :users_profiles do |text, channel|
      Users::Profile.new(id: 1, name: text).broadcast_replace_to(channel, fragment: "profile")
    end
  end

  test "passing extra parameters to channel" do
    visit section_messages_path

    assert_broadcasts_text "In a section", to: :messages do |text|
      Message.create(content: text).broadcast_append_to(:important_messages)
    end
  end

  private

  def reconnect_cable_stream_source(from:, to:)
    cable_stream_source = find("turbo-cable-stream-source[signed-stream-name=#{signed_stream_name(from)}]")

    cable_stream_source.execute_script <<~JS, signed_stream_name(to)
      this.setAttribute("signed-stream-name", arguments[0])
    JS
  end

  def assert_broadcasts_text(text, to:, &block)
    within(:element, id: to) { assert_no_text text }

    [text, to].yield_self(&block)
    sleep 1

    within(:element, id: to) { assert_text text }
  end

  def assert_forwards_turbo_stream_tag_attribute(attr_key:, attr_value:, to:, &block)
    execute_script(<<~SCRIPT)
      Turbo.StreamActions.test = function () {
        const attribute = this.getAttribute('#{attr_key}')

        document.getElementById('#{to}').innerHTML = attribute
      }
    SCRIPT

    within(:element, id: to) { assert_no_text attr_value }

    [attr_key, attr_value, to].yield_self(&block)

    within(:element, id: to) { assert_text attr_value }
  end
end
