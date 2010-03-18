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
        format.xml  { render :xml => @commodity, :status => :created, :location => @commodity }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @commodity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /commodities/1
  def update
    @commodity = Commodity.find(params[:id])

    respond_to do |format|
      if @commodity.update_attributes(params[:commodity])
        flash[:notice] = 'Commodity was successfully updated.'
        format.html { redirect_to(@commodity) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
      end
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
