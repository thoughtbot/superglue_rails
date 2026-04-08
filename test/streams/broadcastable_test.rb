# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

require "test_helper"
require "action_cable"
require "minitest/mock"

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

  test "broadcasting save to stream now" do
    assert_broadcast_on "stream", render_props("save", target: "message_1", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_save_to "stream"
    end
  end

  test "broadcasting save now" do
    assert_broadcast_on @message.to_gid_param, render_props("save", target: "message_1", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_save
    end
  end

  test "broadcasting append to stream now" do
    assert_broadcast_on "stream", render_props("append", target: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append_to "stream"
    end
  end

  test "broadcasting append to stream with custom target now" do
    assert_broadcast_on "stream", render_props("append", target: "board_messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append_to "stream", target: "board_messages"
    end
  end

  test "broadcasting append now" do
    assert_broadcast_on @message.to_gid_param, render_props("append", target: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append
    end
  end

  test "broadcasting prepend to stream now" do
    assert_broadcast_on "stream", render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_prepend_to "stream"
    end
  end

  test "broadcasting prepend to stream with custom target now" do
    assert_broadcast_on "stream", render_props("prepend", target: "board_messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_prepend_to "stream", target: "board_messages"
    end
  end

  test "broadcasting prepend now" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_prepend
    end
  end

  test "broadcasting action to stream now" do
    assert_broadcast_on "stream", render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_action_to "stream", action: "prepend"
    end
  end

  test "broadcasting action now" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_action "prepend"
    end
  end

  test "broadcasting action with attributes" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {"data-foo" => "bar"}) do
      @message.broadcast_action "prepend", target: "messages", options: {"data-foo" => "bar"}
    end
  end

  test "broadcasting action to with attributes" do
    assert_broadcast_on "stream", render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {"data-foo" => "bar"}) do
      @message.broadcast_action_to "stream", action: "prepend", options: {"data-foo" => "bar"}
    end
  end

  test "broadcasting action later to with attributes" do
    @message.save!

    assert_broadcast_on @message.to_gid_param, render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {"data-foo" => "bar"}) do
      perform_enqueued_jobs do
        @message.broadcast_action_later_to @message, action: "prepend", target: "messages", options: {"data-foo" => "bar"}
      end
    end
  end

  test "broadcasting action later with attributes" do
    @message.save!

    assert_broadcast_on @message.to_gid_param, render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {"data-foo" => "bar"}) do
      perform_enqueued_jobs do
        @message.broadcast_action_later action: "prepend", target: "messages", options: {"data-foo" => "bar"}
      end
    end
  end

  test "render correct local name in partial for namespaced models" do
    @profile = Users::Profile.new(id: 1, name: "Ryan")
    assert_broadcast_on @profile.to_param, render_props("save", target: "users_profile_1", partial: @profile.to_partial_path, locals: {profile: @profile}) do
      @profile.broadcast_save
    end
  end

  test "local variables don't get overwritten if they collide with the template name" do
    @profile = Users::Profile.new(id: 1, name: "Ryan")
    assert_broadcast_on @profile.to_param, render_props("save", target: "users_profile_1", partial: @message.to_partial_path, locals: {message: @message}) do
      @profile.broadcast_save partial: "messages/message", locals: {message: @message}
    end
  end

  test "broadcast_append to targets" do
    assert_broadcast_on @message.to_gid_param, render_props("append", targets: ["message_1"], partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append targets: ["message_1"]
    end
  end

  test "broadcast_append targets" do
    assert_broadcast_on @message.to_gid_param, render_props("append", targets: ["message_1"], partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_append targets: ["message_1"]
    end
  end

  test "broadcast_prepend targets" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", targets: ["message_1"], partial: @message.to_partial_path, locals: {message: @message}) do
      @message.broadcast_prepend targets: ["message_1"]
    end
  end

  test "broadcasting append to stream with save_target option" do
    assert_broadcast_on "stream", render_props("append", target: "board_messages", partial: @message.to_partial_path, locals: {message: @message}, options: {save_target: "message_2"}) do
      @message.broadcast_append_to "stream", target: "board_messages", save_target: "message_2"
    end
  end

  test "broadcasting append with save_target option" do
    assert_broadcast_on @message.to_gid_param, render_props("append", target: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {save_target: "custom_message"}) do
      @message.broadcast_append save_target: "custom_message"
    end
  end

  test "broadcasting prepend to stream with save_target option" do
    assert_broadcast_on "stream", render_props("prepend", target: "board_messages", partial: @message.to_partial_path, locals: {message: @message}, options: {save_target: "message_3"}) do
      @message.broadcast_prepend_to "stream", target: "board_messages", save_target: "message_3"
    end
  end

  test "broadcasting prepend with save_target option" do
    assert_broadcast_on @message.to_gid_param, render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {save_target: "custom_prepend_message"}) do
      @message.broadcast_prepend save_target: "custom_prepend_message"
    end
  end

  test "broadcasting append later to stream with save_target option" do
    @message.save!

    assert_broadcast_on "stream", render_props("append", target: "board_messages", partial: @message.to_partial_path, locals: {message: @message}, options: {save_target: "message_later_2"}) do
      perform_enqueued_jobs do
        @message.broadcast_append_later_to "stream", target: "board_messages", save_target: "message_later_2"
      end
    end
  end

  test "broadcasting append later with save_target option" do
    @message.save!

    assert_broadcast_on @message.to_gid_param, render_props("append", target: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {save_target: "custom_later_message"}) do
      perform_enqueued_jobs do
        @message.broadcast_append_later save_target: "custom_later_message"
      end
    end
  end

  test "broadcasting prepend later to stream with save_target option" do
    @message.save!

    assert_broadcast_on "stream", render_props("prepend", target: "board_messages", partial: @message.to_partial_path, locals: {message: @message}, options: {save_target: "message_later_3"}) do
      perform_enqueued_jobs do
        @message.broadcast_prepend_later_to "stream", target: "board_messages", save_target: "message_later_3"
      end
    end
  end

  test "broadcasting prepend later with save_target option" do
    @message.save!

    assert_broadcast_on @message.to_gid_param, render_props("prepend", target: "messages", partial: @message.to_partial_path, locals: {message: @message}, options: {save_target: "custom_later_prepend"}) do
      perform_enqueued_jobs do
        @message.broadcast_prepend_later save_target: "custom_later_prepend"
      end
    end
  end
end

class Superglue::BroadcastableArticleTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  test "creating an article broadcasts to the overriden target with a string" do
    assert_broadcast_on "overriden-stream", render_props("append", target: "overriden-fragment", partial: "articles/article", locals: {article: Article.new(body: "Body")}) do
      perform_enqueued_jobs do
        Article.create!(body: "Body")
      end
    end
  end

  test "updating an article broadcasts" do
    article = Article.create!(body: "Hey")

    assert_broadcast_on "ho", render_props("save", target: "article_#{article.id}", partial: "articles/article", locals: {article: Article.new(body: "Ho")}) do
      perform_enqueued_jobs do
        article.update!(body: "Ho")
      end
    end
  end
end

class Superglue::BroadcastableCommentTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  setup { @article = Article.create!(body: "Body") }

  test "creating a comment broadcasts to the overriden target with a lambda" do
    stream = "#{@article.to_gid_param}:comments"
    target = "article_#{@article.id}_comments"

    assert_broadcast_on stream, render_props("append", target: target, partial: "comments/different_comment", locals: {comment: Comment.new(body: "comment")}) do
      perform_enqueued_jobs do
        @article.comments.create!(body: "comment")
      end
    end
  end

  test "creating a second comment while using locals broadcasts the second comment" do
    stream = "#{@article.to_gid_param}:comments"
    target = "article_#{@article.id}_comments"

    assert_broadcast_on stream, render_props("append", target: target, partial: "comments/different_comment", locals: {comment: Comment.new(body: "comment")}) do
      perform_enqueued_jobs do
        @article.comments.create!(body: "comment")
      end
    end

    assert_broadcast_on stream, render_props("append", target: target, partial: "comments/different_comment", locals: {comment: Comment.new(body: "another comment")}) do
      perform_enqueued_jobs do
        @article.comments.create!(body: "another comment")
      end
    end
  end

  test "updating a comment broadcasts" do
    comment = @article.comments.create!(body: "random")
    stream = "#{@article.to_gid_param}:comments"
    target = "comment_#{comment.id}"

    assert_broadcast_on stream, render_props("save", target: target, partial: "comments/different_comment", locals: {comment: Comment.new(body: "precise")}) do
      perform_enqueued_jobs do
        comment.update!(body: "precise")
      end
    end
  end
end

class Superglue::SuppressingBroadcastsTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  setup { @message = Message.new(id: 1, content: "Hello!") }

  test "suppressing broadcasting save to stream now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_save_to "stream"
    end
  end

  test "suppressing broadcasting save to stream later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_save_later_to "stream"
    end
  end

  test "suppressing broadcasting save now" do
    assert_no_broadcasts_when_suppressing do
      @message.broadcast_save
    end
  end

  test "suppressing broadcasting save later" do
    assert_no_broadcasts_later_when_supressing do
      @message.broadcast_save_later
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
