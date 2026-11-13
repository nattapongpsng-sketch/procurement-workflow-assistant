class BadgeComponent < ApplicationComponent
  TONES = {
    primary: "bg-primary-soft text-primary",
    success: "bg-success-soft text-success",
    neutral: "bg-muted-2 text-neutral-ink",
    future: "bg-accent-soft text-accent-ink",
    danger: "bg-danger-soft text-danger-ink",
    outline: "border border-border-strong text-text-2"
  }.freeze

  def initialize(label = nil, tone: :neutral)
    @label = label
    @tone = TONES.fetch(tone)
  end

  def call
    tag.span(content || @label,
             class: class_names("inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold leading-5", @tone))
  end
end
