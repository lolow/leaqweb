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
    @table = Hash.new("")
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

  # DELETE /ouptuts/1
  def destroy
    @output = Output.find(params[:id])
    @output.destroy
    respond_to do |format|
      format.html { redirect_to(outputs_url) }
    end
  end

end
