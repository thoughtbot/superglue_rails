module Superglue::Broadcastable
  extend ActiveSupport::Concern

  included do
    thread_mattr_accessor :suppressed_superglue_broadcasts, instance_accessor: false
    delegate :suppressed_superglue_broadcasts?, to: "self.class"
  end

  module ClassMethods
    def broadcasts_to(stream, inserts_by: :append, fragment: broadcast_fragment_default, save_as: nil, **rendering)
      after_create_commit -> { broadcast_action_later_to(stream.try(:call, self) || send(stream), action: inserts_by, fragment: fragment.try(:call, self) || fragment, save_as: save_as&.try(:call, self), **rendering) }
      after_update_commit -> { broadcast_save_later_to(stream.try(:call, self) || send(stream), **rendering) }
    end

    def broadcasts(stream = model_name.plural, inserts_by: :append, fragment: broadcast_fragment_default, save_as: nil, **rendering)
      after_create_commit -> { broadcast_action_later_to(stream, action: inserts_by, fragment: fragment.try(:call, self) || fragment, save_as: save_as&.try(:call, self), **rendering) }
      after_update_commit -> { broadcast_save_later(**rendering) }
    end

    def broadcasts_refreshes_to(stream)
      after_commit -> { broadcast_refresh_later_to(stream.try(:call, self) || send(stream)) }
    end

    def broadcasts_refreshes(stream = model_name.plural)
      after_create_commit -> { broadcast_refresh_later_to(stream) }
      after_update_commit -> { broadcast_refresh_later }
      after_destroy_commit -> { broadcast_refresh }
    end

    def broadcast_fragment_default
      model_name.plural
    end

    def suppressing_superglue_broadcasts(&block)
      original, self.suppressed_superglue_broadcasts = suppressed_superglue_broadcasts, true
      yield
    ensure
      self.suppressed_superglue_broadcasts = original
    end

    def suppressed_superglue_broadcasts?
      suppressed_superglue_broadcasts
    end
  end

  # add fragment?
  def broadcast_save_to(*streamables, **rendering)
    Superglue::StreamsChannel.broadcast_save_to(*streamables, **extract_options_and_add_fragment(rendering, fragment: self)) unless suppressed_superglue_broadcasts?
  end

  def broadcast_save(**rendering)
    broadcast_save_to self, **rendering
  end

  # todo save_as: true
  def broadcast_append_to(*streamables, fragment: broadcast_fragment_default, save_as: nil, **rendering)
    Superglue::StreamsChannel.broadcast_append_to(*streamables, save_as: save_as, **extract_options_and_add_fragment(rendering, fragment: fragment)) unless suppressed_superglue_broadcasts?
  end

  def broadcast_append(fragment: broadcast_fragment_default, save_as: nil, **rendering)
    broadcast_append_to self, fragment: fragment, save_as: save_as, **rendering
  end

  def broadcast_prepend_to(*streamables, fragment: broadcast_fragment_default, save_as: nil, **rendering)
    Superglue::StreamsChannel.broadcast_prepend_to(*streamables, save_as: save_as, **extract_options_and_add_fragment(rendering, fragment: fragment)) unless suppressed_superglue_broadcasts?
  end

  def broadcast_prepend(fragment: broadcast_fragment_default, save_as: nil, **rendering)
    broadcast_prepend_to self, fragment: fragment, save_as: save_as, **rendering
  end

  def broadcast_refresh_to(*streamables)
    Superglue::StreamsChannel.broadcast_refresh_to(*streamables) unless suppressed_superglue_broadcasts?
  end

  def broadcast_refresh
    broadcast_refresh_to self
  end

  # todo rename options to js_options
  def broadcast_action_to(*streamables, action:, fragment: broadcast_fragment_default, options: {}, **rendering)
    Superglue::StreamsChannel.broadcast_action_to(*streamables, action: action, options: options, **extract_options_and_add_fragment(rendering, fragment: fragment)) unless suppressed_superglue_broadcasts?
  end

  def broadcast_action(action, fragment: broadcast_fragment_default, options: {}, **rest)
    broadcast_action_to self, action: action, fragment: fragment, options: options, **rest
  end

  def broadcast_save_later_to(*streamables, **rendering)
    Superglue::StreamsChannel.broadcast_save_later_to(*streamables, **extract_options_and_add_fragment(rendering, fragment: self)) unless suppressed_superglue_broadcasts?
  end

  def broadcast_save_later(**rendering)
    broadcast_save_later_to self, **rendering
  end

  def broadcast_append_later_to(*streamables, fragment: broadcast_fragment_default, save_as: nil, **rendering)
    Superglue::StreamsChannel.broadcast_append_later_to(*streamables, save_as: save_as, **extract_options_and_add_fragment(rendering, fragment: fragment)) unless suppressed_superglue_broadcasts?
  end

  def broadcast_append_later(fragment: broadcast_fragment_default, save_as: nil, **rendering)
    broadcast_append_later_to self, fragment: fragment, save_as: save_as, **rendering
  end

  def broadcast_prepend_later_to(*streamables, fragment: broadcast_fragment_default, save_as: nil, **rendering)
    Superglue::StreamsChannel.broadcast_prepend_later_to(*streamables, save_as: save_as, **extract_options_and_add_fragment(rendering, fragment: fragment)) unless suppressed_superglue_broadcasts?
  end

  def broadcast_prepend_later(fragment: broadcast_fragment_default, save_as: nil, **rendering)
    broadcast_prepend_later_to self, fragment: fragment, save_as: save_as, **rendering
  end

  def broadcast_refresh_later_to(*streamables)
    Superglue::StreamsChannel.broadcast_refresh_later_to(*streamables, request_id: Superglue.current_request_id) unless suppressed_superglue_broadcasts?
  end

  def broadcast_refresh_later
    broadcast_refresh_later_to self
  end

  def broadcast_action_later_to(*streamables, action:, fragment: broadcast_fragment_default, options: {}, **rendering)
    Superglue::StreamsChannel.broadcast_action_later_to(*streamables, action: action, options: options, **extract_options_and_add_fragment(rendering, fragment: fragment)) unless suppressed_superglue_broadcasts?
  end

  def broadcast_action_later(action:, fragment: broadcast_fragment_default, options: {}, **rendering)
    broadcast_action_later_to self, action: action, fragment: fragment, options: options, **rendering
  end

  private

  def broadcast_fragment_default
    self.class.broadcast_fragment_default
  end

  def extract_options_and_add_fragment(rendering = {}, fragment: broadcast_fragment_default)
    broadcast_rendering_with_defaults(rendering).tap do |options|
      options[:fragment] = fragment if !options.key?(:fragment) && !options.key?(:fragments)
    end
  end

  def broadcast_rendering_with_defaults(options)
    options.tap do |o|
      # Add the current instance into the locals with the element name (which is the un-namespaced name)
      # as the key. This parallels how the ActionView::ObjectRenderer would create a local variable.
      o[:locals] = (o[:locals] || {}).reverse_merge(model_name.element.to_sym => self).compact

      # if none of these options are passed in, it will set a partial from #to_partial_path
      o[:partial] ||= to_partial_path
    end
  end
end
