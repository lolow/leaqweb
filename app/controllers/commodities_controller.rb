# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class CommoditiesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => [:list, :index]

  def index
    respond_to do |format|
      format.html { @last_visited = last_visited(Commodity) }
      format.js do
        commodities = Commodity.order(:name).select(:name)
        if params[:filter] && params[:filter]!=""
          commodities = commodities.where(["name LIKE ?", "%#{params[:filter]}%"])
        end
        render :json => {"enc"  => commodities.energy_carriers.map(&:name),
                         "poll" => commodities.pollutants.map(&:name),
                         "dem"  => commodities.demands.map(&:name)
                        }.to_json
      end
    end
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
    respond_with(@commodity = Commodity.find(params[:id]) )
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

  def undo_link(object)
    view_context.link_to("(undo)", revert_version_path(object.versions.scoped.last), :method => :post)
  end

  def filter_commodities(params={})
    filter = build_filter(params)
    if params[:set] && params[:set]!="null"
      total = Commodity.tagged_with(params[:set]).count(:conditions => filter[:conditions])
      if current_page * params[:iDisplayLength].to_i > total
        filter[:page] = (total/params[:iDisplayLength].to_i rescue 0) + 1
      end
      displayed = Commodity.tagged_with(params[:set]).paginate(filter)
    else
      total = Commodity.count(:conditions => filter[:conditions])
      displayed = Commodity.paginate(filter)
    end
    return displayed, total
  end

end