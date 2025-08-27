# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

class Superglue::ThreadDebouncer
  delegate :wait, to: :debouncer

  def self.for(key, delay: Superglue::Debouncer::DEFAULT_DELAY)
    Thread.current[key] ||= new(key, Thread.current, delay: delay)
  end

  private_class_method :new

  def initialize(key, thread, delay:)
    @key = key
    @debouncer = Superglue::Debouncer.new(delay: delay)
    @thread = thread
  end

  def debounce
    debouncer.debounce do
      yield.tap do
        thread[key] = nil
      end
    end
  end

  private

  attr_reader :key, :debouncer, :thread
end
