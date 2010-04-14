class SimulationsController < ApplicationController
  before_filter :authenticate_user!
    
  # GET /simulations
  def index
    @simulations = Simulation.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /simulations/1
  def show
    @simulation = Simulation.find(params[:id])
    respond_to do |format|
      format.html { render :show }
    end
  end

  # PUT /simulations/1/import
  def import
    @simulation = Simulation.find(params[:id])
    @simulation.store_results(Solver.find(params[:solver_id]))
    respond_to do |format|
      format.html { redirect_to(@simulation) }
      format.js { render :json => "" }
    end
  end

  # POST /simulations/1/table
  def table
    @simulation = Simulation.find(params[:id])
    selector = params[:selector]
    f = Tempfile.new("temp-sim"+params[:id])
    require 'rinruby'
    R.eval <<EOF
    library('reshape')
    library('R2HTML')
    data <- read.table("#{@simulation.file('csv')}",sep=",",dec=".",h=TRUE)
    data <- subset(data,attribute=="#{selector[:attribute]}")
EOF
    if selector[:filter].size > 0
    R.eval <<EOF
    data <- subset(data,#{selector[:filter]})
EOF
    end
    R.eval <<EOF
    data <- cast(data,#{selector[:formula]},fun.aggregate=sum)
    .HTML.file = "#{f.path}"
    HTML(data,digits=5,append = FALSE,row.names = FALSE)
EOF
    @table_result = f.read
    f.close


#   from rpy2 import robjects
#   table = "Bad formula"
#   try:
#   r = robjects.r
#   r.library('reshape')
#   r.library('R2HTML')
#   #env = robjects.globalEnv
#   import tempfile
#   f = tempfile.NamedTemporaryFile()
#   r('data <- read.table("%s",sep=";",dec=".",h=TRUE)'%s.csv_file.path)
#   r('data <- subset(data,attribute=="%s")' % request.POST['attribute'])
#   if len(request.POST['filter']) > 0:
#      r('data <- subset(data,%s)' % request.POST['filter'])
#   r('data <- cast(data,%s,fun.aggregate=sum)' % request.POST['formula'])
#   r('.HTML.file = "%s"' % f.name)
#   r('HTML(data,digits=5,append = FALSE,row.names = FALSE)')
#   #table = robjects.globalEnv['data'].r_repr()
#   table = open(f.name).read()
#   f.close()
    respond_to do |format|
      format.html { render :show }
    end
  end

  # GET /simulations/new
  def new
    @simulation = Simulation.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /simulations
  def create
    @simulation = Simulation.new(params[:simulation])

    respond_to do |format|
      if @simulation.save
        flash[:notice] = 'Simulation was successfully created.'
        format.html { redirect_to(@simulation) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # DELETE /simulations/1
  def destroy
    @simulation = Simulation.find(params[:id])
    @simulation.destroy

    respond_to do |format|
      format.html { redirect_to(simulations_url) }
    end
  end

end
