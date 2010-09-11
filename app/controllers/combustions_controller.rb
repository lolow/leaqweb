class CombustionsController < ApplicationController

  before_filter :authenticate_user!
  
  # GET /combustions
  def index
    @combustions = Combustion.all
    @combustion = Combustion.new
  end

  # POST /combustions
  def create
    case params[:do]
    when "create"
      @combustion = Combustion.new(params[:combustion])
      respond_to do |format|
        if @combustion.save
          format.html { redirect_to(combustions_path, :notice => 'Combustion coefficient was successfully added.') }
        else
          @combustions = Combustion.all
          format.html { render :action => "index" }
        end
      end
      return
    when "delete"
      ids = Combustion.all.map(&:id).select{|i|params["cb#{i}"]}
      Combustion.destroy(ids)
      flash[:notice]='Combustion coefficients has been deleted.'
    end
    respond_to do |format|
      format.html { redirect_to(combustions_path) }
    end
  end

  # PUT /combustions
  def update
    f = params[:field].split("-")
    @combustion = Combustion.find(f[0].to_i)
    if @combustion.update_attributes(f[1]=>params[:value])
      value = params[:value]
    else
      value = ''
    end
    respond_to do |format|
      format.js { render :json => value }
    end
  end

end
