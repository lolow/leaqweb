class CommoditiesController < ApplicationController
  before_filter :authenticate_user!
  
  # GET /commodities
  def index
    filter = {:page => params[:page],
              :per_page => 30,
              :order => :name}
    if params[:search]
       filter.merge!({:conditions => ['name like ?', "%#{params[:search]}%"]})
    end
    @sets_cloud = Commodity.tag_counts_on(:sets)
    if params[:set]
      @commodities = Commodity.tagged_with(params[:set]).paginate(filter)
    else
      @commodities = Commodity.paginate(filter)
    end
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
        format.html { redirect_to(edit_commodity_path(@commodity)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /commodities/1
  def update
    @commodity = Commodity.find(params[:id])
    # jeditable fields
    if params[:field]
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
        format.js { render :json => value }
      end
    end
    # action on parameter_value
    case params[:do]
    when "update"
      @commodity.update_attributes(params[:commodity])
      respond_to do |format|
        if @commodity.update_attributes(params[:commodity])
          flash[:notice] = 'Commodity was successfully updated.'
          format.html { redirect_to(edit_commodity_path(@commodity)) }
        else
          format.html { render :action => "edit" }
        end
      end
      return
    when "delete_pv"
      ids = @commodity.parameter_values.map(&:id).select{|i|params["cb#{i}"]}
      ParameterValue.destroy(ids)
    when "add_pv"
      att = params[:pv]
      att[:parameter] = Parameter.find_by_name(att[:parameter])
      att[:commodity] = @commodity
      pv = ParameterValue.new(att)
      flash[:notice] = 'Parameter value was successfully added.' if pv.save
    end if params[:do]
    respond_to do |format|
        format.html { redirect_to(edit_commodity_path(@commodity)) }
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
