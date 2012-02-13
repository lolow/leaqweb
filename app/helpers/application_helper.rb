#--
# Copyright (c) 2009-2012, Public Research Center Henri Tudor
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

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

  def title(page_title)
    content_for(:title) { page_title }
  end

end
