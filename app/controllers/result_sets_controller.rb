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

class ResultSetsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, except: :list
  respond_to :json, only:   :list
  
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
    render layout: false, :formats => [:json], partial: "list"
  end

  def update
    @result_set = ResultSet.find(params[:id])
    if @result_set.update_attributes(params[:result_set])
      redirect_to(@result_set, notice: 'Result set was successfully updated.')
    else
      render action: "edit"
    end
  end

  def file
    @result_set = ResultSet.find(params[:id])
    file = @result_set.file(params[:format])
    render text: (File.exist?(file) ?  File.read(file) : "error" )
  end

  def import
    @result_set = ResultSet.find_by_name(params[:result_set_name])
    @result_set = ResultSet.create(name: params[:result_set_name]) unless @result_set
    @result_set.store_solver(SolverJob.find(params[:solver_job_id]))
    respond_to do |format|
      format.html { redirect_to(@result_set) }
      format.js { render json: "" }
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
      render action: "new"
    end
  end

  def destroy
    ResultSet.find(params[:id]).destroy
    redirect_to(result_sets_url)
  end

  def destroy_all
    ResultSet.where(id: checkbox_ids).map(&:destroy)
    redirect_to(result_sets_url)
  end

  def suggest
    res = ResultSet.order(:name).matching_text(params[:term]).limit(10).map(&:name)
    res << "..." if res.size==10
    render json: res.to_json
  end

end