require "test_helper"

class Superglue::RequestIdTrackingTest < ActionDispatch::IntegrationTest
  test "set the current turbo request id from the value in the X-Turbo-Request-Id header" do
    get request_id_path, headers: {"X-Superglue-Request-Id" => "123"}
    #todo: check if its really request_id
    assert_equal "123", JSON.parse(response.body)["request_id"]
  end
end
