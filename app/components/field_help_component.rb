# Explains a field to someone who has never done procurement (design principle 6):
# what it is, an example, and why the form needs it.
class FieldHelpComponent < ApplicationComponent
  def initialize(field_definition)
    @field = field_definition
  end

  def render? = @field.input?

  def call
    tag.div(class: "flex flex-col gap-1 text-[13px] leading-normal text-text-2", id: "#{dom_key}-help") do
      safe_join([
        tag.p(@field.help),
        (tag.p { safe_join([ tag.span("ตัวอย่าง: ", class: "font-medium"), @field.example ]) } if @field.example.present?),
        tag.p { safe_join([ tag.span("ทำไมต้องกรอก: ", class: "font-medium"), @field.why ]) }
      ].compact)
    end
  end

  def dom_key = @field.key.tr(".", "-")
end
