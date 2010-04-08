class SimulationsController < ApplicationController
  before_filter :authenticate_user!
    
  # GET /simulations
  def index
    @simulations = Simulation.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /simulations/1
  def show
    @simulation = Simulation.find(params[:id])
    @solver = current_user.solver
    @solver.update_status if @solver

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # PUT /simulations/1/solver
  # launch next event for solver
  def solver
    @simulation = Simulation.find(params[:id])
    current_user.create_solver unless current_user.solver
    @solver = current_user.solver
    @solver.update_status
    case @solver.current_state.name
      when :new
        @solver.solve!
      when :solving
        @solver.destroy
      when :solved
        @solver.destroy
    end
    respond_to do |format|
      format.html { redirect_to(@simulation) }
    end
  end

  # PUT /simulations/1/import
  def import
    @simulation = Simulation.find(params[:id])
    solver = current_user.solver
    if solver
      solver.prepare_results
      @simulation.store_results(solver)
    end
    respond_to do |format|
      format.html { redirect_to(@simulation) }
    end
  end

  # GET /simulations/new
  def new
    @simulation = Simulation.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /simulations
  def create
    @simulation = Simulation.new(params[:simulation])

    respond_to do |format|
      if @simulation.save
        flash[:notice] = 'Simulation was successfully created.'
        format.html { redirect_to(@simulation) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # DELETE /simulations/1
  def destroy
    @simulation = Simulation.find(params[:id])
    @simulation.destroy

    respond_to do |format|
      format.html { redirect_to(simulations_url) }
    end
  end

end
