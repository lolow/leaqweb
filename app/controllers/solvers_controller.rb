require 'etem_debug'
require 'etem'
require 'yaml'

class SolversController < ApplicationController
  before_filter :authenticate_user!

  def index
    @solvers = Solver.all
    #@outputs = Output.all
    #@solvers.map(&:update_status)
    #@new_solver = Solver.new
    #@refresh = @solvers.inject(false) { |memo,s| memo || s.solving?  }
  end
  
  def new
    @solver = Solver.new
    @solver.opts = Etem::DEF_OPTS
    ['nb_periods','period_length','base_year'].each do |p|
      params[p] =  @solver.opts[p].to_i
    end
  end

  def create
    @solver = Solver.new
    respond_to do |format|
      if @solver.save
        flash[:notice] = 'Solver has successfully started.'
        #@solver.solve!
        format.html {redirect_to(@solver) }
      else
        format.html {render :action => "new"}
      end
    end
  end

  # DELETE /solver/1
  def destroy
    @solver = Solver.find(params[:id])
    @solver.destroy

    respond_to do |format|
      format.html { redirect_to(solver_index_path) }
    end
  end

end
