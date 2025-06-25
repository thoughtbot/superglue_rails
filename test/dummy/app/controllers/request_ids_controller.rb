class RequestIdsController < ApplicationController
  def show
    render json: {request_id: Superglue.current_request_id}
  end
end
