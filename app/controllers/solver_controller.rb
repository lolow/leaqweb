require 'etem_debug'

class SolverController < ApplicationController
  before_filter :authenticate_user!

  # GET /solver
  def index
    @solvers = Solver.all
    @outputs = Output.all
    @solvers.map(&:update_status)
    @new_solver = Solver.new
    @refresh = @solvers.inject(false) { |memo,s| memo || s.solving?  }
    respond_to do |format|
      format.html
    end
  end

  # POST /solver
  def create
    @solvers = Solver.all
    @new_solver = Solver.new
    respond_to do |format|
      if @new_solver.save
        flash[:notice] = 'Solver has successfully started.'
        @new_solver.solve!
        format.html { redirect_to(solver_index_path) }
      else
        format.html {render 'index' }
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
