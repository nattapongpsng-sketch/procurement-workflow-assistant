class ApplicationComponent < ViewComponent::Base
  private

  def class_names(*names) = names.flatten.compact_blank.join(" ")
end
