# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class VersionsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html

  def index
  end

  def list
    @versions, @total_versions = filter_versions(params)
    render :layout => false, :partial => "list.json"
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
    link = view_context.link_to(link_name, revert_version_path(@version.next, :redo => !params[:redo]), :method => :post)
    redirect_to :back, :notice => "Undid #{@version.event}. #{link}"
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
    filter = {:page => current_page,
              :order => "#{order}",
              :conditions => conditions,
              :per_page => params[:iDisplayLength]}
    displayed = Version.paginate filter
    total = Version.count :conditions => conditions
    return displayed, total
  end

end