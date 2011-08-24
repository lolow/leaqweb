# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.
require 'csv'

class ResultSetsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list
  respond_to :csv, :only => :file
  
  def index
  end

  def file_extensions
    Dir[File.join(@result_set.path, "file.*")].collect { |f| File.extname(f)[1..-1].upcase }.sort
  end

  def show
    @result_set = ResultSet.find(params[:id])
    @stored_queries = StoredQuery.order(:name)
    @file_ext = file_extensions
    params[:stored_query] = Hash.new("")
  end

  def list
    @result_sets, @total_result_sets = filter_list(ResultSet)
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
    @result_set = ResultSet.find(params[:id])
    @stored_queries = StoredQuery.order(:name)
    if params[:stored_query][:id].to_i>0
      t = StoredQuery.find(params[:stored_query][:id])
      params[:stored_query][:aggregate] = t.aggregate
      params[:stored_query][:name]      = t.name
      params[:stored_query][:attribute] = t.variable
      params[:stored_query][:formula]   = t.rows + "~" + t.columns
      params[:stored_query][:filter]    = t.filters
      params[:stored_query][:rows]      = t.rows
      params[:stored_query][:columns]   = t.columns
      params[:stored_query][:display]   = t.display
    end
    @result_set.perform_query(params[:stored_query])
    @file_ext = file_extensions
    render :show
  end

  def file
    @result_set = ResultSet.find(params[:id])
    render :text => text(params[:format])
  end

  def import
    @result_set = ResultSet.find(params[:id])
    @result_set.store_solver(Solver.find(params[:solver_id]))
    respond_to do |format|
      format.html { redirect_to(@result_set) }
      format.js { render :json => "" }
    end
  end

  def new
    @result_set = ResultSet.new
  end

  def create
    @result_set = ResultSet.new(params[:result_set])
    if @result_set.save
      flash[:notice] = 'ResultSet was successfully created.'
      redirect_to(@result_set)
    else
      render :action => "new"
    end
  end

  def destroy
    ResultSet.destroy(params[:id])
    redirect_to(result_sets_url)
  end

  def destroy_all
    ResultSet.destroy(checkbox_ids)
    redirect_to(result_sets_url)
  end

  private

  def text(suffix)
    if File.exist?(@result_set.file(suffix))
      File.read(@result_set.file(suffix))
    else
      "error"
    end
  end

  def filter_result_sets(params={})
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    filter = {:page => current_page,
              :per_page => params[:iDisplayLength]}
    displayed = ResultSet.matching_text(params[:sSearch]).paginate filter
    total     = ResultSet.matching_text(params[:sSearch]).count
    return displayed, total
  end

end