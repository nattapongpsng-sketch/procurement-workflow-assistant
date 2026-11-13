# Top bar from the UI canvas: logo "จัดซื้อง่าย" + main navigation.
class AppHeaderComponent < ApplicationComponent
  def initialize(current: "search")
    @current = current.to_s
  end

  def call
    tag.header(class: "sticky top-0 z-10 border-b border-border bg-surface") do
      tag.div(class: "mx-auto flex h-16 max-w-[1200px] items-center gap-6 px-4 sm:px-6") do
        safe_join([ logo, navigation ])
      end
    end
  end

  private

  def logo
    link_to(helpers.root_path, class: "flex items-center gap-2 font-bold text-text no-underline hover:text-text") do
      safe_join([ tag.span("จง", class: "grid size-8 place-items-center rounded-ctl bg-primary text-sm text-on-primary",
                                 aria: { hidden: true }), "จัดซื้อง่าย" ])
    end
  end

  def navigation
    tag.nav(aria: { label: "เมนูหลัก" }, class: "flex items-center gap-1 text-[15px]") do
      safe_join([
        nav_link("ค้นหา Workflow", helpers.root_path, "search"),
        tag.span(class: "flex items-center gap-2 rounded-ctl px-3 py-2 text-text-2", title: "เปิดใช้ใน Milestone 1") do
          safe_join([ "เรื่องของฉัน", render(BadgeComponent.new("เร็ว ๆ นี้", tone: :future)) ])
        end
      ])
    end
  end

  def nav_link(label, path, key)
    active = key == @current
    link_to(label, path, aria: { current: (active ? "page" : nil) },
                         class: class_names("rounded-ctl px-3 py-2 font-medium no-underline",
                                            active ? "bg-primary-soft text-primary" : "text-text-2 hover:bg-muted"))
  end
end
