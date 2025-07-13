require "test_helper"

class Superglue::StreamsControllerTest < ActionDispatch::IntegrationTest
  test "create with respond to" do
    post messages_path
    assert_redirected_to message_path(id: 1)

    post messages_path, as: :json
    assert_equal(response.parsed_body[:data],
      [
        {
          "fragmentIds" => ["message_1"],
          "handler" => "save",
          "options" => {},
          "data" => {
            "body" => "My message"
          }
        }
      ])

    assert_equal 200, status
  end
end
