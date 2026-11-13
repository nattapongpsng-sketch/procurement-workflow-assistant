# Buttons from the design system: contained (primary action), outlined, text.
# Renders a link when `href` is given, otherwise a <button>.
class ButtonComponent < ApplicationComponent
  VARIANTS = {
    contained: "bg-primary text-on-primary hover:bg-primary-hover hover:text-on-primary active:bg-primary-pressed",
    outlined: "border border-border-strong bg-surface text-primary hover:bg-primary-soft active:bg-primary-soft-pressed",
    text: "text-primary hover:bg-primary-soft active:bg-primary-soft-pressed"
  }.freeze
  SIZES = { sm: "h-9 px-3 text-sm", md: "h-11 px-4 text-[15px]", lg: "h-12 px-5 text-base" }.freeze

  def initialize(label = nil, href: nil, variant: :contained, size: :md, type: "button", disabled: false, **attributes)
    @label = label
    @href = href
    @variant = VARIANTS.fetch(variant)
    @size = SIZES.fetch(size)
    @type = type
    @disabled = disabled
    @attributes = attributes
  end

  def call
    classes = class_names("inline-flex items-center justify-center gap-2 rounded-ctl font-medium no-underline transition-colors",
                          "disabled:cursor-not-allowed disabled:bg-muted-2 disabled:text-text-3 disabled:border-transparent",
                          @variant, @size, @attributes.delete(:class))
    body = content || @label
    if @href && !@disabled
      link_to(body, @href, class: classes, **@attributes)
    else
      tag.button(body, type: @type, disabled: @disabled, class: classes, **@attributes)
    end
  end
end
