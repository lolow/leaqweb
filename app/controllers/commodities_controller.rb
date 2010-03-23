class CommoditiesController < ApplicationController
  before_filter :authenticate_user!
  
  # GET /commodities
  def index
    ["page","per_page"].each do |p|
      user_session["comm_#{p}"] = params[p] if params[p]
    end
    filter = {:page => user_session["comm_page"],
              :per_page => user_session["comm_per_page"],
              :order => :name}
    if params[:search]
       filter.merge!({:conditions => ['name like ?', "%#{params[:search]}%"]})
    end
    @commodities = Commodity.paginate(filter)
    respond_to do |format|
      format.html
    end
  end

  # GET /commodities/1
  def show
    @commodity = Commodity.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # GET /commodities/new
  def new
    newname = 'NEWCOM'
    @commodity = Commodity.new

    respond_to do |format|
      format.html
    end
  end

  # GET /commodities/1/edit
  def edit
    @commodity = Commodity.find(params[:id])
  end

  # POST /commodities
  def create
    @commodity = Commodity.new(params[:commodity])

    respond_to do |format|
      if @commodity.save
        flash[:notice] = 'Commodity was successfully created.'
        format.html { redirect_to(@commodity) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /commodities/1
  def update
    @commodity = Commodity.find(params[:id])
    f = params[:field].split("-")
    if f[0]=="pv"
      record = ParameterValue.find(f[1].to_i)
      attributes = {f[2]=>params[:value]}
    else
      record = @commodity
      attributes = {params[:field]=>params[:value]}
    end
    if record.update_attributes(attributes)
      value = params[:value]
    else
      value = ''
    end
    respond_to do |format|
      format.html { redirect_to(@commodity) }
      format.js { render :json => value }
    end
  end

  # DELETE /commodities/1
  def destroy
    @commodity = Commodity.find(params[:id])
    @commodity.destroy

    respond_to do |format|
      format.html { redirect_to(commodities_url) }
    end
  end
end
