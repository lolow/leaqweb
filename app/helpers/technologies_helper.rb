module TechnologiesHelper
  def commodity_url_list(flow)
    "(" + flow.commodities.collect { |c|
      link_to(h(c.name), edit_commodity_path(c))
    }.join(", ") + ")"
  end
  def commodity_list(flow)
    "(" + flow.commodities.collect { |c| h(c.name) }.join(", ") + ")"
  end
end
