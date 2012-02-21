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
# NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

class CommoditySetsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :check_res!

  respond_to :html
  respond_to :json, only: [:show, :suggest]

  def index
  end

  def list
    @commodity_sets, @total_commodity_sets  = filter_list(commodity_sets,%w(name description))
    render layout: false, partial: "list.json"
  end

  def show
    @commodity_set = CommoditySet.find(params[:id])
    respond_to do |format|
      format.html { redirect_to edit_commodity_set_path(@commodity_set) }
      format.js { render json: {commodity_set: {id: @commodity_set.id, commodities: @commodity_set.commodities}}.to_json }
    end
  end

  def new
    respond_with(@commodity_set = CommoditySet.new)
  end

  def edit
    respond_with(@commodity_set = CommoditySet.find(params[:id]))
  end

  def create
    respond_with(@commodity_set = CommoditySet.create(params[:commodity_set]))
  end

  def update
    @commodity_set = CommoditySet.find(params[:id])
    case params[:do]
      when "update_commodities"
        @commodity_set.commodities = Commodity.find_by_list_name(params[:commodities])
        flash[:notice] = 'Commodity set was successfully created.' if @commodity_set.save
      when "update"
        @commodity_set.update_attributes(params[:commodity_set])
        respond_with(@commodity_set)
        return
      when "delete_pv"
        ParameterValue.where(id: checkbox_ids).map(&:destroy)
      when "add_pv"
        att = params[:pv]
        att[:parameter] = Parameter.find_by_name(att[:parameter])
        att[:commodity] = Commodity.find_by_name(att[:commodity]) if att[:commodity]
        att[:commodity_set] = @commodity_set
        pv = ParameterValue.new(att)
        flash[:notice] = 'Parameter value was successfully added.' if pv.save
    end if params[:do]
    redirect_to(edit_commodity_set_path(@commodity_set))
  end

  def destroy
    CommoditySet.find(params[:id]).destroy
    redirect_to(commodity_sets_url)
  end

  def destroy_all
    CommoditySet.where(:id=>checkbox_ids).map(&:destroy)
    redirect_to(commodity_sets_url)
  end

  def suggest
    text = params[:term]
    res = CommoditySet.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render json: res.to_json
  end

  private

  def commodity_sets
    CommoditySet.where(:energy_system_id=>@current_res)
  end

end
