# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class StoredQueriesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  def index
    @stored_queries = StoredQuery.order(:name)
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
end
