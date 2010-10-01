# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class CommoditiesController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  def index
    filter = {:page => params[:page],
      :per_page => 30,
      :order => :name}
    if params[:search]
      filter.merge!({:conditions => ['name like ?', "%#{params[:search]}%"]})
    end
    @last_visited = last_visited(Commodity)
    if params[:set]
      @commodities = Commodity.tagged_with(params[:set]).paginate(filter)
    else
      @commodities = Commodity.paginate(filter)
    end
  end

  def show
    @commodity = Commodity.find(params[:id])
    redirect_to edit_commodity_path(@commodity)
  end

  def new
    respond_with(@commodity = Commodity.new)
  end

  def edit
    new_visit(Commodity,params[:id])
    @commodity = Commodity.includes(:parameter_values).find(params[:id])
    respond_with(@commodity)
  end

  def create
    respond_with(@commodity = Commodity.new(params[:commodity]))
  end

  def duplicate
    @commodity = Commodity.find(params[:id]).duplicate
    redirect_to(edit_commodity_path(@commodity))
  end

  def update
    @commodity = Commodity.find(params[:id])
    case params[:do]
    when "update"
      @commodity.update_attributes(params[:commodity])
      respond_with(@commodity)
      return
    when "delete_pv"
      ParameterValue.destroy(checkbox_ids)
    when "add_pv"
      att = params[:pv]
      att[:parameter] = Parameter.find_by_name(att[:parameter])
      att[:commodity] = @commodity
      pv = ParameterValue.new(att)
      flash[:notice] = 'Parameter value was successfully added.' if pv.save
    end if params[:do]
    redirect_to(edit_commodity_path(@commodity))
  end

  def destroy
    Commodity.destroy(params[:id])
    redirect_to(commodities_url)
  end

end
