#--
# Copyright (c) 2009-2012, Public Research Center Henri Tudor
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

class CommoditiesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => [:list, :suggest]
  respond_to :json, :only => [:list, :suggest]

  def index
    respond_to do |format|
      format.html { @last_visited = last_visited(Commodity) }
      format.js do
        commodities = Commodity.matching_text(params[:filter]).order(:name).select(:name)
        render :json => {"enc"  => commodities.energy_carriers.map(&:name),
                         "poll" => commodities.pollutants.map(&:name),
                         "dem"  => commodities.demands.map(&:name)
                        }.to_json
      end
    end
  end

  def list
    @commodities, @total_commodities  = filter_list(Commodity,["name","description"])
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
    Commodity.find(params[:id]).destroy
    redirect_to(commodities_url)
  end

  def destroy_all
    Commodity.where(:id=>checkbox_ids).map(&:destroy)
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
        ParameterValue.where(:id=>checkbox_ids).map(&:destroy)
      when "add_pv"
        att = params[:pv]
        att[:parameter] = Parameter.find_by_name(att[:parameter])
        att[:commodity] = @commodity
        pv = ParameterValue.new(att)
        flash[:notice] = 'Parameter value was successfully added.' if pv.save
    end if params[:do]
    redirect_to(edit_commodity_path(@commodity))
  end

  def suggest
    text = params[:term]
    res = Commodity.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render :json => res.to_json
  end

  def suggest_pollutant
    text = params[:term]
    res = Commodity.pollutants.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render :json => res.to_json
  end

  def suggest_fuel
    text = params[:term]
    res = Commodity.energy_carriers.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render :json => res.to_json
  end

  private

  def undo_link(object)
    view_context.link_to("(undo)", revert_version_path(object.versions.scoped.last), :method => :post)
  end

end