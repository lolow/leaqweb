# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.
class ResultSetsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list
  
  def index
  end

  def show
    redirect_to edit_result_set_path(ResultSet.find(params[:id]))
  end

  def edit
    @result_set = ResultSet.find(params[:id])
    @file_ext = Dir[File.join(@result_set.path, "file.*")].collect { |f| File.extname(f)[1..-1].upcase }.sort
  end

  def list
    @result_sets, @total_result_sets = filter_list(ResultSet)
    render :layout => false, :partial => "list.json"
  end

  def update
    @result_set = ResultSet.find(params[:id])
    if @result_set.update_attributes(params[:result_set])
      redirect_to(@result_set, :notice => 'Result set was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def file
    @result_set = ResultSet.find(params[:id])
    file = @result_set.file(params[:format])
    render :text => (File.exist?(file) ?  File.read(file) : "error" )
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

end