class TechnologiesController < ApplicationController
  before_filter :authenticate_user!
  
  # GET /technologies
  # GET /technologies.xml
  def index
    @technologies = Technology.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @technologies }
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

    respond_to do |format|
      if @technology.update_attributes(params[:technology])
        flash[:notice] = 'Technology was successfully updated.'
        format.html { redirect_to(@technology) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @technology.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /technologies/1
  # DELETE /technologies/1.xml
  def destroy
    @technology = Technology.find(params[:id])
    @technology.destroy

    respond_to do |format|
      format.html { redirect_to(technologies_url) }
      format.xml  { head :ok }
    end
  end
end
