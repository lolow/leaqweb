class OutputsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @outputs = Output.all
    respond_to { |format| format.html }
  end

  def show
    @output = Output.find(params[:id])
    @queries = Query.order(:name)
    params[:query] = Hash.new("")
    render :show
  end

  def update
    if params[:commit]=="Store this query as"
      @query = Query.new()
      name = params[:query][:name]
      @query.name = @query.next_available_name(Query, name)
      @query.aggregate = params[:query][:aggregate]
      @query.variable  = params[:query][:attribute]
      formula = params[:query][:formula].split("~")
      @query.rows      = formula[0] if formula.size==2
      @query.columns   = formula[1] if formula.size==2
      @query.filters   = params[:query][:filter]
      if @query.save
        redirect_to @query
        return
      else
        flash[:notice] = "Wrong query definition"
        render :template => "query/new"
        return
      end
    end
    @output  = Output.find(params[:id])
    @queries = Query.order(:name)
    if params[:query][:id].to_i>0
      t = Query.find(params[:query][:id])
      params[:query][:aggregate] = t.aggregate
      params[:query][:name] = t.name
      params[:query][:attribute] = t.variable
      params[:query][:formula] = t.rows + "~" + t.columns
      params[:query][:filter] = t.filters
    end
    @output.compute_cross_tab(params[:query])
    params[:query][:result] = @output.cross_tab
    render :show
  end

  def csv
    @output = Output.find(params[:id])
    render :text => File.read(@output.file('csv'))
  end

  def import
    @output = Output.find(params[:id])
    @output.store_solver(Solver.find(params[:solver_id]))
    respond_to do |format|
      format.html { redirect_to(@output) }
      format.js { render :json => "" }
    end
  end

  def new
    @output = Output.new
  end

  def create
    @output = Output.new(params[:output])
      if @output.save
        flash[:notice] = 'Output was successfully created.'
        redirect_to(@output)
      else
        render :action => "new"
      end
  end

  def destroy
    @output = Output.find(params[:id])
    @output.destroy
    redirect_to(outputs_url)
  end

end
