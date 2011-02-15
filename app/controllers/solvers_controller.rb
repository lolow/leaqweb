require 'etem_debug'
require 'etem'
require 'yaml'

class SolversController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html
  
  def index
    @solvers = Solver.all
    @solvers.map(&:update_status)
  end
  
  def new
    @solver = Solver.new
    @solver.opts = Etem::DEF_OPTS
    p @solver.opts
    [:nb_periods,:period_duration,:first_year,:language].each do |p|
      params[p] =  @solver.opts[p]
    end
  end
  
  def create
    @solver = Solver.new
    @solver.opts = {
      :base_year => params[:base_year].to_i,
      :nb_periods => params[:nb_periods].to_i,
      :period_length => params[:period_length].to_i,
      :language => params[:language]
    }
    if @solver.save
      flash[:notice] = 'Solver has successfully started.'
      @solver.solve!
      redirect_to(@solver)
    else
      p @solver.errors
      render :action => "new"
    end
  end
  
  def show
    @outputs = Output.all
    @solver = Solver.find(params[:id])
    @solver.update_status
    @refresh = @solver.solving?
    respond_with(@solver)
  end

  # DELETE /solver/1
  def destroy
    @solver = Solver.find(params[:id])
    @solver.destroy
    redirect_to(solvers_path)
  end

end
