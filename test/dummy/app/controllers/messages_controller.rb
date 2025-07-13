class MessagesController < ApplicationController
  def show
    @message = Message.find(params[:id])

    if (other_id = params[:other_message])
      @other_message = Message.find(other_id)
    end
  end

  def index
    @messages = Message.all
  end

  def section
  end

  def create
    @message = Message.new(id: 1, content: "My message")

    respond_to do |format|
      format.html { redirect_to message_url(id: 1) }
      format.json { render layout: "stream" }
    end
  end

  def update
    @message = Message.new(id: params[:id], content: "Updated message")

    respond_to do |format|
      format.html { redirect_to message_url(id: params[:id]) }
      format.json { render layout: "stream" }
    end
  end
end
