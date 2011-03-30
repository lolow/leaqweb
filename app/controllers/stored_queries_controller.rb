# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class StoredQueriesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list

  def index
  end

  def list
    @stored_queries, @total_stored_queries = filter_stored_queries(params)
    render :layout => false, :partial => "list.json"
  end

  def show
    redirect_to edit_stored_query_path(StoredQuery.find(params[:id]))
  end

  def new
    respond_with(@stored_query = StoredQuery.new)
  end

  def duplicate
    @stored_query = StoredQuery.find(params[:id]).duplicate_as_new
    render :action => "new"
  end

  def edit
    respond_with(@stored_query = StoredQuery.find(params[:id]))
  end

  def create
    respond_with(@stored_query = StoredQuery.create(params[:stored_query]))
  end

  def update
    @stored_query = StoredQuery.find(params[:id])
    if @stored_query.update_attributes(params[:stored_query])
      redirect_to(@stored_query, :notice => 'Query was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    StoredQuery.destroy(params[:id])
    redirect_to(stored_queries_url)
  end

  def destroy_all
    StoredQuery.destroy(checkbox_ids)
    redirect_to(stored_queries_url)
  end

  private

  def filter_stored_queries(params={})
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    columns = [nil,"name"]
    order   = columns[params[:iSortCol_0] ? params[:iSortCol_0].to_i : 0]
    conditions = []
    if params[:sSearch] && params[:sSearch]!=""
      conditions = ['name LIKE ?'] + ["%#{params[:sSearch]}%"]
    end
    filter = {:page => current_page,
              :order => "#{order} #{params[:sSortDir_0] || "DESC"}",
              :conditions => conditions,
              :per_page => params[:iDisplayLength]}
    displayed = StoredQuery.paginate filter
    total = StoredQuery.count :conditions => conditions
    return displayed, total
  end

end
