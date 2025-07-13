require "application_system_test_case"
require "json"

class StreamResponseTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper
  extend Superglue::Streams::StreamName

  setup do
    setup_superglue_dependency
  end

  test "Message broadcasts Turbo Streams" do
    message = Message.create(content: "Hello!")
    visit message_path(message)

    assert_text "Hello"
    assert_no_text "Updated message"

    click_on "Update Message"

    assert_no_text "Hello"
    assert_text "Updated message"
  end
end
