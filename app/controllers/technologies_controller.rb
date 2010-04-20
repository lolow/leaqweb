class TechnologiesController < ApplicationController
  before_filter :authenticate_user!
  
  # GET /technologies
  def index
    ["page","per_page"].each do |p|
      user_session["tech_#{p}"] = params[p] if params[p]
    end
    filter = {:page => user_session["tech_page"],
              :per_page => user_session["tech_per_page"],
              :order => :name}
    if params[:search]
       filter.merge!({:conditions => ['name like ?', "%#{params[:search]}%"]})
    end
    @sets_cloud = Technology.tag_counts_on(:sets)
    if params[:sets]
      @technologies = Technology.tagged_with(params[:sets]).paginate(filter)
    else
      @technologies = Technology.paginate(filter)
    end
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /technologies/1
  def show
    @technology = Technology.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /technologies/new
  def new
    @technology = Technology.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /technologies/1/edit
  def edit
    @technology = Technology.find(params[:id])
  end

  # POST /technologies
  def create
    @technology = Technology.new(params[:technology])

    respond_to do |format|
      if @technology.save
        flash[:notice] = 'Technology was successfully created.'
        format.html { redirect_to(@technology) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /technologies/1
  def update
    @technology = Technology.find(params[:id])
    # jeditable fields
    if params[:field]
      f = params[:field].split("-")
      if f[0]=="pv"
        record = ParameterValue.find(f[1].to_i)
        attributes = {f[2]=>params[:value]}
      else
        record = @technology
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
    when "delete_pv"
      ids = @technology.parameter_values.map(&:id).select{|i|params["cb#{i}"]}
      ParameterValue.destroy(ids)
    when "add_pv"
      att = params[:pv]
      att[:parameter] = Parameter.find_by_name(att[:parameter])
      att[:commodity] = Commodity.find_by_name(att[:commodity]) if att[:commodity]
      att[:technology] = @technology
      pv = ParameterValue.new(att)
      flash[:notice] = 'Parameter value was successfully added.' if pv.save
    when "set_act_flo"
      ids = @technology.flows.map(&:id).select{|i|params["f#{i}"]}
      @technology.flow_act=Flow.find(ids[0]) if ids.size>0
    when "delete_flo"
      ids = @technology.flows.map(&:id).select{|i|params["f#{i}"]}
      Flow.destroy(ids)
    end if params[:do]
    respond_to do |format|
        format.html { redirect_to(@technology) }
    end
  end

  # DELETE /technologies/1
  def destroy
    @technology = Technology.find(params[:id])
    @technology.destroy

    respond_to do |format|
      format.html { redirect_to(technologies_url) }
    end
  end
end
