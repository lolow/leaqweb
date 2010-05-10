class OutputsController < ApplicationController
  before_filter :authenticate_user!

  # GET /outputs
  def index
    @outputs = Output.all
    respond_to { |format| format.html }
  end

  # GET /outputs/1
  def show
    @output = Output.find(params[:id])
    @tables =  Table.find(:all,:order => :name )
    params[:table] = Hash.new("")
    respond_to do |format|
      format.html { render :show }
    end
  end

  # PUT /outputs/1
  def update
    @output = Output.find(params[:id])
    @tables = Table.find(:all,:order => :name )
    if params[:table][:id].to_i>0
      t = Table.find(params[:table][:id])
      params[:table][:aggregate] = t.aggregate
      params[:table][:name] = t.name
      params[:table][:attribute] = t.variable
      params[:table][:formula] = t.rows + "~" + t.columns
      params[:table][:filter] = t.filters
    end
    @output.compute_cross_tab(params[:table])
    params[:table][:result] = @output.cross_tab
    respond_to do |format|
      format.html { render :show }
    end
  end

  # GET /outputs/1/csv
  def csv
    @output = Output.find(params[:id])
    respond_to do |format|
      format.html { render :text => File.read(@output.csv) }
    end
  end

  # PUT /outputs/1/import
  def import
    @output = Output.find(params[:id])
    @output.store_solver(Solver.find(params[:solver_id]))
    respond_to do |format|
      format.html { redirect_to(@output) }
      format.js { render :json => "" }
    end
  end

  # GET /outputs/new
  def new
    @output = Output.new
    respond_to { |format| format.html }
  end

  # POST /outputs
  def create
    @output = Output.new(params[:output])
    respond_to do |format|
      if @output.save
        flash[:notice] = 'Output was successfully created.'
        format.html { redirect_to(@output) }
      else
        format.html { render :action => "new" }
      end
    end
  end


  # DELETE /outputs/1
  def destroy
    @output = Output.find(params[:id])
    @output.destroy
    respond_to do |format|
      format.html { redirect_to(outputs_url) }
    end
  end

end