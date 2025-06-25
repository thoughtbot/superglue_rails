require "test_helper"
require "action_cable"
require "minitest/mock"

def render_refresh(request_id = nil)
  JSON.generate({
    type: "message",
    action: "refresh",
    requestId: request_id,
    options: {}
  })
end

class Superglue::BroadcastableTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  class MessageThatRendersError < Message
    def to_partial_path
      "messages/raises_error"
    end
  end

  setup { @message = Message.new(id: 1, content: "Hello!") }

  test "broadcasting ignores blank streamables" do
    ActionCable.server.stub :broadcast, proc { flunk "expected no broadcasts" } do
      assert_no_broadcasts @message.to_gid_param do
        @message.broadcast_append_to nil
        @message.broadcast_append_to [nil]
        @message.broadcast_append_to ""
        @message.broadcast_append_to [""]
      end
    end
  end

  test "broadcasting later ignores blank streamables" do
    assert_no_enqueued_jobs do
      @message.broadcast_append_later_to nil
      @message.broadcast_append_later_to [nil]
      @message.broadcast_append_later_to ""
      @message.broadcast_append_later_to [""]
    end
  end

  test "broadcasting replace to stream now" do
    assert_broadcast_on "stream", render_props("replace", fragment: "message_1", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_replace_to "stream"
    end
  end

  test "broadcasting replace now" do
    assert_broadcast_on @message.to_gid_param, render_props("replace", fragment: "message_1", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_replace
    end
  end

  test "broadcasting append to stream now" do
    assert_broadcast_on "stream", render_props("append", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append_to "stream"
    end
  end

  test "broadcasting append to stream with custom fragment now" do
    assert_broadcast_on "stream", render_props("append", fragment: "board_messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append_to "stream", fragment: "board_messages"
    end
  end

  test "broadcasting append now" do
    assert_broadcast_on @message.to_gid_param, render_props("append", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append
    end
  end

  test "broadcasting prepend to stream now" do
    assert_broadcast_on "stream", render_props("prepend", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_prepend_to "stream"
    end
  end

  test "broadcasting prepend to stream with custom fragment now" do
    assert_broadcast_on "stream", render_props("prepend", fragment: "board_messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_prepend_to "stream", fragment: "board_messages"
    end
  end

  test "broadcasting prepend now" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_prepend
    end
  end

  test "broadcasting refresh to stream now" do
    assert_broadcast_on "stream", render_refresh do
      @message.broadcast_refresh_to "stream"
    end
  end

  test "broadcasting refresh now" do
    assert_broadcast_on @message.to_gid_param, render_refresh do
      @message.broadcast_refresh
    end
  end

  test "broadcasting refresh does not render contents" do
    message = MessageThatRendersError.new(id: 1)

    assert_broadcast_on message.to_gid_param, render_refresh do
      message.broadcast_refresh
    end
  end

  test "broadcasting refresh later is debounced" do
    assert_broadcast_on @message.to_gid_param, render_refresh do
      assert_broadcasts(@message.to_gid_param, 1) do
        perform_enqueued_jobs do
          assert_no_changes -> { Thread.current.keys.size } do
            # Not leaking thread variables once the debounced code executes
            3.times { @message.broadcast_refresh_later }
            Superglue::StreamsChannel.refresh_debouncer_for(@message).wait
          end
        end
      end
    end
  end

  test "broadcasting action to stream now" do
    assert_broadcast_on "stream", render_props("prepend", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_action_to "stream", action: "prepend"
    end
  end

  test "broadcasting action now" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_action "prepend"
    end
  end

  test "broadcasting action with attributes" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {"data-foo" => "bar"}) do
      @message.broadcast_action "prepend", fragment: "messages", options: {"data-foo" => "bar"}
    end
  end

  test "broadcasting action to with attributes" do
    assert_broadcast_on "stream", render_props("prepend", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {"data-foo" => "bar"}) do
      @message.broadcast_action_to "stream", action: "prepend", options: {"data-foo" => "bar"}
    end
  end

  test "broadcasting action later to with attributes" do
    @message.save!

    assert_broadcast_on @message.to_gid_param, render_props("prepend", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {"data-foo" => "bar"}) do
      perform_enqueued_jobs do
        @message.broadcast_action_later_to @message, action: "prepend", fragment: "messages", options: {"data-foo" => "bar"}
      end
    end
  end

  test "broadcasting action later with attributes" do
    @message.save!

    assert_broadcast_on @message.to_gid_param, render_props("prepend", fragment: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {"data-foo" => "bar"}) do
      perform_enqueued_jobs do
        @message.broadcast_action_later action: "prepend", fragment: "messages", options: {"data-foo" => "bar"}
      end
    end
  end

  test "render correct local name in partial for namespaced models" do
    @profile = Users::Profile.new(id: 1, name: "Ryan")
    assert_broadcast_on @profile.to_param, render_props("replace", fragment: "users_profile_1", partial: @profile.to_partial_path, locals: {profile: @profile}) do
      @profile.broadcast_replace
    end
  end

  test "local variables don't get overwritten if they collide with the template name" do
    @profile = Users::Profile.new(id: 1, name: "Ryan")
    assert_broadcast_on @profile.to_param, render_props("replace", fragment: "users_profile_1", partial: @message.to_partial_path, locals: {message: @message}) do
      @profile.broadcast_replace partial: "messages/message", locals: {message: @message}
    end
  end

  test "broadcast_append to fragments" do
    assert_broadcast_on @message.to_gid_param, render_props("append", fragments: ["message_1"], partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append fragments: ["message_1"]
    end
  end

  test "broadcast_append fragments" do
    assert_broadcast_on @message.to_gid_param, render_props("append", fragments: ["message_1"], partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append fragments: ["message_1"]
    end
  end

  test "broadcast_prepend fragments" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", fragments: ["message_1"], partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_prepend fragments: ["message_1"]
    end
  end
end

class Superglue::BroadcastableArticleTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  test "creating an article broadcasts to the overriden fragment with a string" do
    assert_broadcast_on "overriden-stream", render_props("append", fragment: "overriden-fragment", partial: "articles/article", locals: {article: Article.new(body: "Body")}) do
      perform_enqueued_jobs do
        Article.create!(body: "Body")
      end
    end
  end

  test "updating an article broadcasts" do
    article = Article.create!(body: "Hey")

    assert_broadcast_on "ho", render_props("replace", fragment: "article_#{article.id}", partial: "articles/article", locals: {article: Article.new(body: "Ho")}) do
      perform_enqueued_jobs do
        article.update!(body: "Ho")
      end
    end
  end
end

class Superglue::BroadcastableCommentTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  setup { @article = Article.create!(body: "Body") }

  test "creating a comment broadcasts to the overriden fragment with a lambda" do
    stream = "#{@article.to_gid_param}:comments"
    fragment = "article_#{@article.id}_comments"

    assert_broadcast_on stream, render_props("append", fragment: fragment, partial: "comments/different_comment", locals: {comment: Comment.new(body: "comment")}) do
      perform_enqueued_jobs do
        @article.comments.create!(body: "comment")
      end
    end
  end

  test "creating a second comment while using locals broadcasts the second comment" do
    stream = "#{@article.to_gid_param}:comments"
    fragment = "article_#{@article.id}_comments"

    assert_broadcast_on stream, render_props("append", fragment: fragment, partial: "comments/different_comment", locals: {comment: Comment.new(body: "comment")}) do
      perform_enqueued_jobs do
        @article.comments.create!(body: "comment")
      end
    end

    assert_broadcast_on stream, render_props("append", fragment: fragment, partial: "comments/different_comment", locals: {comment: Comment.new(body: "another comment")}) do
      perform_enqueued_jobs do
        @article.comments.create!(body: "another comment")
      end
    end
  end

  test "updating a comment broadcasts" do
    comment = @article.comments.create!(body: "random")
    stream = "#{@article.to_gid_param}:comments"
    fragment = "comment_#{comment.id}"

    assert_broadcast_on stream, render_props("replace", fragment: fragment, partial: "comments/different_comment", locals: {comment: Comment.new(body: "precise")}) do
      perform_enqueued_jobs do
        comment.update!(body: "precise")
      end
    end
  end
end

class Superglue::BroadcastableBoardTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  test "creating a board broadcasts refreshes to a channel using models plural name when creating" do
    assert_broadcast_on "boards", render_refresh do
      perform_enqueued_jobs do
        Board.create!(name: "Board")
        Superglue::StreamsChannel.refresh_debouncer_for(["boards"]).wait
      end
    end
  end

  test "updating a board broadcasts to the models channel" do
    board = Board.suppressing_superglue_broadcasts do
      Board.create!(name: "Hey")
    end

    assert_broadcast_on board.to_gid_param, render_refresh do
      perform_enqueued_jobs do
        board.update!(name: "Ho")
        Superglue::StreamsChannel.refresh_debouncer_for(board).wait
      end
    end
  end

  test "destroying a board broadcasts refreshes to the model channel" do
    board = Board.suppressing_superglue_broadcasts do
      Board.create!(name: "Hey")
    end

    assert_broadcast_on board.to_gid_param, render_refresh do
      board.destroy!
    end
  end
end

class Superglue::SuppressingBroadcastsTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  setup { @message = Message.new(id: 1, content: "Hello!") }

  test "suppressing broadcasting replace to stream now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_replace_to "stream"
    end
  end

  test "suppressing broadcasting replace to stream later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_replace_later_to "stream"
    end
  end

  test "suppressing broadcasting replace now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_replace
    end
  end

  test "suppressing broadcasting replace later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_replace_later
    end
  end

  test "suppressing broadcasting append to stream now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_append_to "stream"
    end
  end

  test "suppressing broadcasting append to stream later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_append_later_to "stream"
    end
  end

  test "suppressing broadcasting append now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_append
    end
  end

  test "suppressing broadcasting append later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_append_later
    end
  end

  test "suppressing broadcasting prepend to stream now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_prepend_to "stream"
    end
  end

  test "suppressing broadcasting prepend to stream later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_prepend_later_to "stream"
    end
  end

  test "suppressing broadcasting refresh to stream now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_refresh_to "stream"
    end
  end

  test "suppressing broadcasting refresh to stream later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_refresh_later_to "stream"
    end
  end

  test "suppressing broadcasting prepend now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_prepend
    end
  end

  test "suppressing broadcasting prepend later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_prepend_later
    end
  end

  test "suppressing broadcasting action to stream now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_action_to "stream", action: "prepend"
    end
  end

  test "suppressing broadcasting action to stream later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_action_later_to "stream", action: "prepend"
    end
  end

  test "suppressing broadcasting action now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_action "prepend"
    end
  end

  test "suppressing broadcasting action later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_action_later action: "prepend"
    end
  end

  private

  def assert_no_broadcasts_when_suppressing
    assert_no_broadcasts @message.to_gid_param do
      Message.suppressing_superglue_broadcasts do
        yield
      end
    end
  end

  def assert_no_broadcasts_later_when_supressing
    assert_no_broadcasts_when_suppressing do
      assert_no_enqueued_jobs do
        yield
      end
    end
  end
end
