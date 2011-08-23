module ApplicationHelper
    def commodity_url_list(flow)
    "(" + flow.commodities.collect { |c|
      link_to(h(c.name), edit_commodity_path(c))
    }.join(", ") + ")".html_safe
  end

  def commodity_list(flow)
    "(" + flow.commodities.collect { |c| h(c.name) }.join(", ") + ")".html_safe
  end

  def short_flow(flow)
    return "" unless flow
    s = "#{flow.id}"
    s += ": (" + truncate(h(flow.commodities.first.name), :omission => "...", :length => 10) if flow.commodities.size > 0
    s += ",..." if flow.commodities.size > 1
    s += ")" if flow.commodities.size > 0
    s
  end
end
