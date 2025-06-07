module Turbo::Broadcastable
  extend ActiveSupport::Concern

  included do
    thread_mattr_accessor :suppressed_turbo_broadcasts, instance_accessor: false
    delegate :suppressed_turbo_broadcasts?, to: "self.class"
  end

  module ClassMethods
    def broadcasts_to(stream, inserts_by: :append, target: broadcast_target_default, **rendering)
      after_create_commit  -> { broadcast_action_later_to(stream.try(:call, self) || send(stream), action: inserts_by, target: target.try(:call, self) || target, **rendering) }
      after_update_commit  -> { broadcast_replace_later_to(stream.try(:call, self) || send(stream), **rendering) }
      after_destroy_commit -> { broadcast_remove_to(stream.try(:call, self) || send(stream)) }
    end

    def broadcasts(stream = model_name.plural, inserts_by: :append, target: broadcast_target_default, **rendering)
      after_create_commit  -> { broadcast_action_later_to(stream, action: inserts_by, target: target.try(:call, self) || target, **rendering) }
      after_update_commit  -> { broadcast_replace_later(**rendering) }
      after_destroy_commit -> { broadcast_remove }
    end

    def broadcasts_refreshes_to(stream)
      after_commit -> { broadcast_refresh_later_to(stream.try(:call, self) || send(stream)) }
    end

    def broadcasts_refreshes(stream = model_name.plural)
      after_create_commit  -> { broadcast_refresh_later_to(stream) }
      after_update_commit  -> { broadcast_refresh_later }
      after_destroy_commit -> { broadcast_refresh }
    end

    def broadcast_target_default
      model_name.plural
    end

    def suppressing_turbo_broadcasts(&block)
      original, self.suppressed_turbo_broadcasts = self.suppressed_turbo_broadcasts, true
      yield
    ensure
      self.suppressed_turbo_broadcasts = original
    end

    def suppressed_turbo_broadcasts?
      suppressed_turbo_broadcasts
    end
  end

  def broadcast_remove_to(*streamables, target: self, **rendering)
    Turbo::StreamsChannel.broadcast_remove_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_remove(**rendering)
    broadcast_remove_to self, **rendering
  end

  def broadcast_replace_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_replace_to(*streamables, **extract_options_and_add_target(rendering, target: self)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_replace(**rendering)
    broadcast_replace_to self, **rendering
  end

  def broadcast_before_to(*streamables, target: nil, targets: nil, **rendering)
    raise ArgumentError, "at least one of target or targets is required" unless target || targets

    Turbo::StreamsChannel.broadcast_before_to(*streamables, **extract_options_and_add_target(rendering.merge(target: target, targets: targets)))
  end

  def broadcast_after_to(*streamables, target: nil, targets: nil, **rendering)
    raise ArgumentError, "at least one of target or targets is required" unless target || targets

    Turbo::StreamsChannel.broadcast_after_to(*streamables, **extract_options_and_add_target(rendering.merge(target: target, targets: targets)))
  end

  def broadcast_append_to(*streamables, target: broadcast_target_default, **rendering)
    Turbo::StreamsChannel.broadcast_append_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_append(target: broadcast_target_default, **rendering)
    broadcast_append_to self, target: target, **rendering
  end

  def broadcast_prepend_to(*streamables, target: broadcast_target_default, **rendering)
    Turbo::StreamsChannel.broadcast_prepend_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_prepend(target: broadcast_target_default, **rendering)
    broadcast_prepend_to self, target: target, **rendering
  end

  def broadcast_refresh_to(*streamables)
    Turbo::StreamsChannel.broadcast_refresh_to(*streamables) unless suppressed_turbo_broadcasts?
  end

  def broadcast_refresh
    broadcast_refresh_to self
  end

  def broadcast_action_to(*streamables, action:, target: broadcast_target_default, attributes: {}, **rendering)
    Turbo::StreamsChannel.broadcast_action_to(*streamables, action: action, attributes: attributes, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_action(action, target: broadcast_target_default, attributes: {}, **rendering)
    broadcast_action_to self, action: action, target: target, attributes: attributes, **rendering
  end

  def broadcast_replace_later_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_replace_later_to(*streamables, **extract_options_and_add_target(rendering, target: self)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_replace_later(**rendering)
    broadcast_replace_later_to self, **rendering
  end

  def broadcast_append_later_to(*streamables, target: broadcast_target_default, **rendering)
    Turbo::StreamsChannel.broadcast_append_later_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_append_later(target: broadcast_target_default, **rendering)
    broadcast_append_later_to self, target: target, **rendering
  end

  def broadcast_prepend_later_to(*streamables, target: broadcast_target_default, **rendering)
    Turbo::StreamsChannel.broadcast_prepend_later_to(*streamables, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_prepend_later(target: broadcast_target_default, **rendering)
    broadcast_prepend_later_to self, target: target, **rendering
  end

  def broadcast_refresh_later_to(*streamables)
    Turbo::StreamsChannel.broadcast_refresh_later_to(*streamables, request_id: Turbo.current_request_id) unless suppressed_turbo_broadcasts?
  end

  def broadcast_refresh_later
    broadcast_refresh_later_to self
  end

  def broadcast_action_later_to(*streamables, action:, target: broadcast_target_default, attributes: {}, **rendering)
    Turbo::StreamsChannel.broadcast_action_later_to(*streamables, action: action, attributes: attributes, **extract_options_and_add_target(rendering, target: target)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_action_later(action:, target: broadcast_target_default, attributes: {}, **rendering)
    broadcast_action_later_to self, action: action, target: target, attributes: attributes, **rendering
  end

  def broadcast_render(**rendering)
    broadcast_render_to self, **rendering
  end

  def broadcast_render_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_render_to(*streamables, **extract_options_and_add_target(rendering, target: self)) unless suppressed_turbo_broadcasts?
  end

  def broadcast_render_later(**rendering)
    broadcast_render_later_to self, **rendering
  end

  def broadcast_render_later_to(*streamables, **rendering)
    Turbo::StreamsChannel.broadcast_render_later_to(*streamables, **extract_options_and_add_target(rendering)) unless suppressed_turbo_broadcasts?
  end

  private
    def broadcast_target_default
      self.class.broadcast_target_default
    end

    def extract_options_and_add_target(rendering = {}, target: broadcast_target_default)
      broadcast_rendering_with_defaults(rendering).tap do |options|
        options[:target] = target if !options.key?(:target) && !options.key?(:targets)
      end
    end

    def broadcast_rendering_with_defaults(options)
      options.tap do |o|
        o[:locals] = (o[:locals] || {}).reverse_merge(model_name.element.to_sym => self).compact

        if o[:html] || o[:partial]
          return o
        elsif o[:template] || o[:renderable]
          o[:layout] = false
        elsif o[:render] == false
          return o
        else
          o[:partial] ||= to_partial_path
        end
      end
    end
end
