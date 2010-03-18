module CommoditiesHelper
  def technology_url_list(technologies)
    technologies.collect { |t|
      link_to(h(t.name), technology_path(t))
    }.join(", ")
  end
end
