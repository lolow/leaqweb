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
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'etem_debug'
require 'yaml'

class SolversController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list

  USER_OPTION = [:nb_periods, :period_duration, :first_year, :language, :scenarios]

  respond_to :html

  def index
    Solver.all.map(&:update_status)
  end

  def list
    @solvers, @total_solvers = filter_list(Solver)
    render :layout => false, :partial => "list.json"
  end

  def new
    @solver = Solver.new
    USER_OPTION.each do |attr|
      @solver[attr] = Etem::DEF_OPTS[attr]
    end
  end

  def create
    @solver = Solver.create(params[:solver])
    if @solver.save
      flash[:notice] = 'Solver has successfully started.'
      @solver.solve!
      redirect_to(@solver)
    else
      render :action => "new"
    end
  end

  def show
    @result_sets = ResultSet.all
    @solver = Solver.find(params[:id])
    @solver.update_status
    @refresh = @solver.solving?
    respond_with(@solver)
  end

  def destroy
    Solver.destroy(params[:id])
    redirect_to(solvers_path)
  end

  def destroy_all
    Solver.destroy(checkbox_ids)
    redirect_to(solvers_path)
  end

  def run
  end

end
