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

require 'yaml'

class SolverJobsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :check_res!

  respond_to :html, except: :list
  respond_to :json, only:   :list

  respond_to :html

  def index
  end

  def list
    @solver_jobs, @total_solver_jobs = filter_list(solver_jobs)
    render layout: false, :formats => [:json], partial: "list"
  end

  def new
    @solver_job = SolverJob.new(scenarios: "BASE")
  end

  def create
    @solver_job = SolverJob.new(params[:solver_job])
    if @solver_job.save
      @solver_job.etem_solver.setup
      @solver_job.delay.solve
      redirect_to(@solver_job)
    else
      render :action => "new"
    end
  end

  def show
    @solver_job = SolverJob.find(params[:id])
    @state = @solver_job.etem_solver.read(:state)
    respond_with(@solver_job)
  end

  def destroy
    SolverJob.find(params[:id]).destroy
    redirect_to(solver_jobs_path)
  end

  def destroy_all
    SolverJob.where(id: checkbox_ids).map(&:destroy)
    redirect_to(solver_jobs_path)
  end

  private

  def solver_jobs
    SolverJob.where(:energy_system_id=>@current_res)
  end

end
