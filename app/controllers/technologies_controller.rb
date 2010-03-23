class TechnologiesController < ApplicationController
  before_filter :authenticate_user!
  
  # GET /technologies
  # GET /technologies.xml
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
    @technologies = Technology.paginate(filter)
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => Technology.all }
    end
  end

  # GET /technologies/1
  # GET /technologies/1.xml
  def show
    @technology = Technology.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @technology }
    end
  end

  # GET /technologies/new
  # GET /technologies/new.xml
  def new
    @technology = Technology.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @technology }
    end
  end

  # GET /technologies/1/edit
  def edit
    @technology = Technology.find(params[:id])
  end

  # POST /technologies
  # POST /technologies.xml
  def create
    @technology = Technology.new(params[:technology])

    respond_to do |format|
      if @technology.save
        flash[:notice] = 'Technology was successfully created.'
        format.html { redirect_to(@technology) }
        format.xml  { render :xml => @technology, :status => :created, :location => @technology }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @technology.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /technologies/1
  # PUT /technologies/1.xml
  def update
    @technology = Technology.find(params[:id])
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
      format.html { redirect_to(@technology) }
      format.js { render :json => value }
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
