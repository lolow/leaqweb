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
    #jobhandler = JobHandler.instance
    #@solver = jobhandler.job(current_user.id)
    #@slot = jobhandler.slot_available? unless @solver

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # PUT /simulations/1/start
  def start
    @simulation = Simulation.find(params[:id])
    #jobhandler = JobHandler.instance
    #jobhandler.kill(current_user.id)
    #s = GeoecuSolver.new
    #jobhandler.assign(current_user.id,s)
    #s.solve
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
