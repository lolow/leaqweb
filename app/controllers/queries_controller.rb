# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class QueriesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  def index
    @queries = Query.order(:name)
  end

  def show
    redirect_to edit_query_path(Query.find(params[:id]))
  end

  def new
    respond_with(@query = Query.new)
  end

  def duplicate
    @query = Query.find(params[:id]).duplicate_as_new
    render :action => "new"
  end

  def edit
    respond_with(@query = Query.find(params[:id]))
  end

  def create
    respond_with(@query = Query.create(params[:query]))
  end

  def update
    @query = Query.find(params[:id])
    if @query.update_attributes(params[:query])
      redirect_to(@query, :notice => 'Query was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    Query.destroy(params[:id])
    redirect_to(queries_url)
  end
end
