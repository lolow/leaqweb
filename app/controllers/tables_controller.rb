class TablesController < ApplicationController
  before_filter :authenticate_user!

  # GET /tables
  def index
    @tables = Table.order(:name)
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /tables/1
  def show
    @table = Table.find(params[:id])
    respond_to do |format|
      format.html { redirect_to edit_table_path(@table) }
    end
  end

  # GET /tables/new
  def new
    @table = Table.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /tables/clone/1
  def clone
    @table = Table.find(params[:id]).clone
    respond_to do |format|
      format.html {render :action => "new"}
    end
  end

  # GET /tables/1/edit
  def edit
    @table = Table.find(params[:id])
  end

  # POST /tables
  def create
    @table = Table.new(params[:table])
    respond_to do |format|
      if @table.save
        flash[:notice] = 'Table was successfully created.'
        format.html { redirect_to(@table) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /tables/1
  def update
    @table = Table.find(params[:id])
    respond_to do |format|
      if @table.update_attributes(params[:table])
        flash[:notice] = 'Table was successfully updated.'
        format.html { redirect_to(@table) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /tables/1
  def destroy
    @table = Table.find(params[:id])
    @table.destroy
    respond_to do |format|
      format.html { redirect_to(tables_url) }
    end
  end
end
