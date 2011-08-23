# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class StoredQueriesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list

  def index
    params[:display] = "pivot_table" unless params[:display]
  end

  def list
    @stored_queries, @total_stored_queries = filter_list(StoredQuery,["name"])
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

end
