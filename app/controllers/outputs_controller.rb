# Copyright (c) 2009-2011, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

require 'csv'

class OutputsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list

  def index
  end

  def show
    @output = Output.find(params[:id])
    @stored_queries = StoredQuery.order(:name)
    params[:stored_query] = Hash.new("")
    render :show
  end

  def list
    @outputs, @total_outputs = filter_outputs(params)
    render :layout => false, :partial => "list.json"
  end

  def update
    if params[:commit]=="Store this query as"
      @stored_query = StoredQuery.new()
      name = params[:stored_query][:name]
      @stored_query.name = @stored_query.next_available_name(StoredQuery, name)
      @stored_query.aggregate = params[:stored_query][:aggregate]
      @stored_query.variable = params[:stored_query][:attribute]
      formula = params[:stored_query][:formula].split("~")
      @stored_query.rows = formula[0] if formula.size==2
      @stored_query.columns = formula[1] if formula.size==2
      @stored_query.filters = params[:stored_query][:filter]
      if @stored_query.save
        redirect_to @stored_query
        return
      else
        flash[:notice] = "Wrong query definition"
        render :template => "stored_query/new"
        return
      end
    end
    @output = Output.find(params[:id])
    @stored_queries = StoredQuery.order(:name)
    if params[:stored_query][:id].to_i>0
      t = StoredQuery.find(params[:stored_query][:id])
      params[:stored_query][:aggregate] = t.aggregate
      params[:stored_query][:name] = t.name
      params[:stored_query][:attribute] = t.variable
      params[:stored_query][:formula] = t.rows + "~" + t.columns
      params[:stored_query][:filter] = t.filters
    end
    @output.compute_cross_tab(params[:stored_query])
    params[:stored_query][:result] = @output.cross_tab
    render :show
  end

  def csv
    @output = Output.find(params[:id])
    render :text => File.read(@output.file('csv'))
  end

  def import
    @output = Output.find(params[:id])
    @output.store_solver(Solver.find(params[:solver_id]))
    respond_to do |format|
      format.html { redirect_to(@output) }
      format.js { render :json => "" }
    end
  end

  def new
    @output = Output.new
  end

  def create
    @output = Output.new(params[:output])
    if @output.save
      flash[:notice] = 'Output was successfully created.'
      redirect_to(@output)
    else
      render :action => "new"
    end
  end

  def destroy
    Output.destroy(params[:id])
    redirect_to(outputs_url)
  end

  def destroy_all
    Output.destroy(checkbox_ids)
    redirect_to(outputs_url)
  end

  private

  def filter_outputs(params={})
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    filter = {:page => current_page,
              :per_page => params[:iDisplayLength]}
    displayed = Output.all.paginate filter
    total     = Output.count
    return displayed, total
  end

end
