module TechnologiesHelper
  def commodity_url_list(flow)
    "(" + flow.commodities.collect { |c|
      link_to(h(c.name), edit_commodity_path(c))
    }.join(", ") + ")"
  end
  def commodity_list(flow)
    "(" + flow.commodities.collect { |c| h(c.name) }.join(", ") + ")"
  end
  def short_flow(flow)
    return "" unless flow
    s = "#{flow.id}"
    s += ": (" + truncate(h(flow.commodities.first.name), :omission => "&hellip;", :length => 10) if flow.commodities.size > 0
    s += ",&hellip;" if flow.commodities.size > 1
    s += ")" if flow.commodities.size > 0
    s
  end
end
