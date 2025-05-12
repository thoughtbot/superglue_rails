module Superglue::Streams::ActionHelper
  private

  def convert_to_superglue_fragment_id(target, include_selector: false)
    target_array = Array.wrap(target)
    if target_array.any? { |value| value.respond_to?(:to_key) }
      ActionView::RecordIdentifier.dom_id(*target_array)
    else
      target
    end
  end
end
