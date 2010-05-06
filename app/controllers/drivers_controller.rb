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

  # GET /commodities/new
  def new
    @demand_driver = DemandDriver.new
    respond_to do |format|
      format.html
    end
  end

end
