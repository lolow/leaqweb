module LayoutHelper

  def common_js
    jquery = %w(jquery.min jquery-ui.min jquery.blockui jquery.datatables.min jquery-fluid16 jquery.jeditable jquery.jqplot.min jquery.cookie)
    mine = %w(rails application)
    javascript_include_tag(jquery) + javascript_include_tag(mine)
  end

end