class DriversController < ApplicationController
  before_filter :authenticate_user!

  # GET /drivers
  def index
    filter = {:page => params[:page],
              :per_page => 30,
              :order => :name}
    @demand_drivers = DemandDriver.paginate(filter)
    respond_to do |format|
      format.html
    end
  end

  # GET /drivers/1
  def show
    @demand_driver = DemandDriver.find(params[:id])
    respond_to do |format|
      format.html { redirect_to edit_demand_driver_path(@demand_driver) }
    end
  end

  # GET /drivers/1/edit
  def edit
    @demand_driver = DemandDriver.find(params[:id])
  end

  # GET /drivers/new
  def new
    @demand_driver = DemandDriver.new
    respond_to do |format|
      format.html
    end
  end

  # POST /drivers
  def create
    @demand_driver = DemandDriver.new(params[:demand_driver])
    respond_to do |format|
      if @demand_driver.save
        flash[:notice] = 'Demand driver was successfully created.'
        format.html { redirect_to(@demand_driver) }
      else
        format.html { render :action => "new" }
      end
    end
  end

end
