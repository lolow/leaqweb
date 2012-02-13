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

class VersionsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html

  def index
  end

  def list
    @versions, @total_versions = filter_versions(params)
    render layout: false, partial: "list.json"
  end

  def show
    require 'yaml'
    @version = Version.find(params[:id])
    @object  = YAML.load(@version.object) if @version.object
    respond_with(@version)
  end

  def revert
    @version = Version.find(params[:id])
    if @version.reify
      @version.reify.save!
    else
      @version.item.destroy
    end
    link_name = params[:redo] == "true" ? "(undo)" : "(redo)"
    link = view_context.link_to(link_name, revert_version_path(@version.next, redo: !params[:redo]), method: :post)
    redirect_to :back, notice: "Undid #{@version.event}. #{link}"
  end

  private

  def filter_versions(params={})
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    dir =  params[:sSortDir_0] || "DESC"
    columns = ["created_at #{dir}","event #{dir}","item_type #{dir}, item_id #{dir}","whodunnit #{dir}"]
    order   = columns[params[:iSortCol_0] ? params[:iSortCol_0].to_i : 0]
    conditions = []
    if params[:sSearch] && params[:sSearch]!=""
      conditions = ['event LIKE ? OR item_type LIKE ? OR item_id LIKE ?'] + ["%#{params[:sSearch]}%"] * 3
    end
    filter = {page: current_page,
              order: "#{order}",
              conditions: conditions,
              per_page: params[:iDisplayLength]}
    displayed = Version.paginate filter
    total = Version.count conditions: conditions
    return displayed, total
  end

end