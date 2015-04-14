module ApplicationHelper
  def active_nav_item(controller, action)
    current_page?(controller: controller, action: action) ? 'active' : ''
  end
end
