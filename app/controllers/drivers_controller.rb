class DriversController < ApplicationController
  before_filter :authenticate_user!

  # GET /drivers
  def index
    @demand_drivers = DemandDriver.all
    respond_to do |format|
      format.html
    end
  end

end
