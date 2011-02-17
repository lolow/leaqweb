class OutputsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @outputs = Output.all
    respond_to { |format| format.html }
  end

  def show
    @output = Output.find(params[:id])
    @stored_queries = StoredQuery.order(:name)
    params[:stored_query] = Hash.new("")
    render :show
  end

  def update
    if params[:commit]=="Store this query as"
      @stored_query = StoredQuery.new()
      name = params[:stored_query][:name]
      @stored_query.name = @stored_query.next_available_name(StoredQuery, name)
      @stored_query.aggregate = params[:stored_query][:aggregate]
      @stored_query.variable = params[:stored_query][:attribute]
      formula = params[:stored_query][:formula].split("~")
      @stored_query.rows = formula[0] if formula.size==2
      @stored_query.columns = formula[1] if formula.size==2
      @stored_query.filters = params[:stored_query][:filter]
      if @stored_query.save
        redirect_to @stored_query
        return
      else
        flash[:notice] = "Wrong query definition"
        render :template => "stored_query/new"
        return
      end
    end
    @output = Output.find(params[:id])
    @stored_queries = StoredQuery.order(:name)
    if params[:stored_query][:id].to_i>0
      t = StoredQuery.find(params[:stored_query][:id])
      params[:stored_query][:aggregate] = t.aggregate
      params[:stored_query][:name] = t.name
      params[:stored_query][:attribute] = t.variable
      params[:stored_query][:formula] = t.rows + "~" + t.columns
      params[:stored_query][:filter] = t.filters
    end
    @output.compute_cross_tab(params[:stored_query])
    params[:stored_query][:result] = @output.cross_tab
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
