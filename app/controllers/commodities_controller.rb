# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class CommoditiesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list

  def index
    @last_visited = last_visited(Commodity)
  end

  def list
    @commodities, @total_commodities  = filter_commodities(params)
    render :layout => false, :partial => "list.json"
  end

  def show
    redirect_to edit_commodity_path(Commodity.find(params[:id]))
  end

  def new
    respond_with(@commodity = Commodity.new)
  end

  def edit
    new_visit(Commodity, params[:id])
    @commodity = Commodity.includes(:parameter_values).find(params[:id])
    respond_with(@commodity)
  end

  def create
    respond_with(@commodity = Commodity.create(params[:commodity]))
  end

  def destroy
    Commodity.destroy(params[:id])
    redirect_to(commodities_url)
  end

  def destroy_all
    Commodity.destroy(checkbox_ids)
    redirect_to(commodities_url)
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

  private

  def filter_commodities(params={})
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    columns = [nil,"name","description"]
    order   = columns[params[:iSortCol_0] ? params[:iSortCol_0].to_i : 0]
    conditions = []
    if params[:sSearch] && params[:sSearch]!=""
      conditions = ['name LIKE ? OR description LIKE ?'] + ["%#{params[:sSearch]}%"] * 2
    end
    filter = {:page => current_page,
              :order => "#{order} #{params[:sSortDir_0] || "DESC"}",
              :conditions => conditions,
              :per_page => params[:iDisplayLength]}
    if params[:set] && params[:set]!="null"
      displayed = Commodity.tagged_with(params[:set]).paginate filter
      total = Commodity.tagged_with(params[:set]).count :conditions => conditions
    else
      displayed = Commodity.paginate filter
      total = Commodity.count :conditions => conditions
    end
    return displayed, total
  end

end