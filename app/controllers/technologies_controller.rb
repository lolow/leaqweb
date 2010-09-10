class TechnologiesController < ApplicationController
  before_filter :authenticate_user!
  
  # GET /technologies
  def index
    filter = {:page => params[:page],
              :per_page => 30,
              :order => :name}
    if params[:search]
       filter.merge!({:conditions => ['name like ?', "%#{params[:search]}%"]})
    end
    @last_visited = Technology.where(:id=>Array(session[:last_tech]))
    @sets_cloud = Technology.tag_counts_on(:sets)
    if params[:set]
      @technologies = Technology.tagged_with(params[:set]).paginate(filter)
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
      format.html {redirect_to edit_technology_path(@technology)}
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
    last = Array(session[:last_tech])
    last.unshift(params[:id])[0,10] unless last.include? params[:id]
    session[:last_tech] = last
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

  # POST /technologies/1/clone
  def duplicate
    @technology = Technology.find(params[:id]).duplicate
    respond_to do |format|
      format.html { redirect_to(edit_technology_path(@technology)) }
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
      return
    end
    # action on parameter_value
    case params[:do]
    when "preprocess_input_output"
      @technology.preprocess_input_output
    when "update"
      respond_to do |format|
        if @technology.update_attributes(params[:technology])
          flash[:notice] = 'Technology was successfully updated.'
          format.html { redirect_to(edit_technology_path(@technology)) }
        else
          format.html { render :action => "edit" }
        end
      end
      return
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
        format.html { redirect_to(edit_technology_path(@technology)) }
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