class DemandDriversController < ApplicationController
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

  # DELETE /drivers/1
  def destroy
    @demand_driver = DemandDriver.find(params[:id])
    @demand_driver.destroy

    respond_to do |format|
      format.html { redirect_to(demand_drivers_url) }
    end
  end

  # PUT /drivers/1
  def update
    @demand_driver = DemandDriver.find(params[:id])
    # jeditable fields
    if params[:field]
      f = params[:field].split("-")
      record = ParameterValue.find(f[1].to_i)
      attributes = {f[2]=>params[:value]}
      if record.update_attributes(attributes)
        value = params[:value]
      else
        value = ''
      end
      respond_to do |format|
        format.js { render :json => value }
      end
      return
    end
    # action on parameter_value
    case params[:do]
      when "update"
        respond_to do |format|
          if @demand_driver.update_attributes(params[:demand_driver])
            flash[:notice] = 'Demand driver was successfully updated.'
            format.html { redirect_to(edit_demand_driver_path(@technology)) }
          else
            format.html { render :action => "edit" }
          end
        end
        return
      when "delete_pv"
        ids = @demand_driver.parameter_values.map(&:id).select { |i| params["cb#{i}"] }
        ParameterValue.destroy(ids)
      when "add_pv"
        att = params[:pv]
        att[:parameter] = @demand_driver
        pv = ParameterValue.new(att)
        flash[:notice] = 'Demand driver value was successfully added.' if pv.save
    end if params[:do]
    respond_to do |format|
      format.html { redirect_to(edit_demand_driver_path(@demand_driver)) }
    end
  end

end
