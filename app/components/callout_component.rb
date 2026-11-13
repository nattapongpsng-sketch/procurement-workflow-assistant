# Highlighted message box. Use `warn` for things the user must act on and
# `error` with a reason plus what to do next (design principle 4).
class CalloutComponent < ApplicationComponent
  TONES = {
    info: "bg-primary-soft text-primary-ink",
    ok: "bg-success-soft text-success-ink",
    warn: "bg-accent-soft text-accent-ink",
    error: "bg-danger-soft text-danger-ink"
  }.freeze

  def initialize(tone: :info, title: nil)
    @tone = tone
    @title = title
  end

  def call
    tag.div(role: (@tone == :error ? "alert" : nil),
            class: class_names("rounded-card px-4 py-3 text-sm leading-relaxed", TONES.fetch(@tone))) do
      safe_join([ (tag.p(@title, class: "font-semibold") if @title), content ].compact)
    end
  end
end
