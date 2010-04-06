class SimulationsController < ApplicationController
  # GET /simulations
  # GET /simulations.xml
  def index
    @simulations = Simulation.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @simulations }
    end
  end

  # GET /simulations/1
  # GET /simulations/1.xml
  def show
    @simulation = Simulation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @simulation }
    end
  end

  # GET /simulations/new
  # GET /simulations/new.xml
  def new
    @simulation = Simulation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @simulation }
    end
  end

  # GET /simulations/1/edit
  def edit
    @simulation = Simulation.find(params[:id])
  end

  # POST /simulations
  # POST /simulations.xml
  def create
    @simulation = Simulation.new(params[:simulation])

    respond_to do |format|
      if @simulation.save
        flash[:notice] = 'Simulation was successfully created.'
        format.html { redirect_to(@simulation) }
        format.xml  { render :xml => @simulation, :status => :created, :location => @simulation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @simulation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /simulations/1
  # PUT /simulations/1.xml
  def update
    @simulation = Simulation.find(params[:id])

    respond_to do |format|
      if @simulation.update_attributes(params[:simulation])
        flash[:notice] = 'Simulation was successfully updated.'
        format.html { redirect_to(@simulation) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @simulation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /simulations/1
  # DELETE /simulations/1.xml
  def destroy
    @simulation = Simulation.find(params[:id])
    @simulation.destroy

    respond_to do |format|
      format.html { redirect_to(simulations_url) }
      format.xml  { head :ok }
    end
  end
end
