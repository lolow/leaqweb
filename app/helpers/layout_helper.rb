module LayoutHelper

  def common_js
    jquery = %w(jquery.min jquery-ui.min jquery.blockui jquery.datatables.min jquery.livequery)
    jquery << "jquery-fluid16" << "jquery.jeditable" << "jquery.jqplot.min"
    jquery << "jquery.cookie"
    jquery << "jquery.scrollTo-min"
    jquery << "jquery.tmpl"
    jquery << "ui.multiselect"
    mine = %w(rails application)
    javascript_include_tag(jquery) + javascript_include_tag(mine)
  end

end