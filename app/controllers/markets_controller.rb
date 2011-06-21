# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class MarketsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html
  respond_to :json, :only => [:show]

  def index
    @markets = Market.order(:name)
  end

  def show
    @market = Market.find(params[:id])
    respond_to do |format|
      format.html { redirect_to edit_market_path(@market) }
      format.js { render :json => {:market=>{:id=>@market.id, :technologies=>@market.technologies}}.to_json }
    end
  end

  def new
    respond_with(@market = Market.new)
  end

  def edit
    respond_with(@market = Market.find(params[:id]))
  end

  def create
    respond_with(@market = Market.create(params[:market]))
  end

  def update
    @market = Market.find(params[:id])
    case params[:do]
      when "update_technologies"
        @market.technologies = Technology.find_by_list_name(params[:technologies])
        flash[:notice] = 'Market was successfully created.' if @market.save
      when "update"
        @market.update_attributes(params[:market])
        respond_with(@market)
        return
      when "delete_pv"
        ParameterValue.destroy(checkbox_ids)
      when "add_pv"
        att = params[:pv]
        att[:sub_market] = Market.find(att[:sub_market].to_i) if att[:sub_market]
        att[:parameter] = Parameter.find_by_name(att[:parameter])
        att[:market] = @market
        pv = ParameterValue.new(att)
        flash[:notice] = 'Parameter value was successfully added.' if pv.save
    end if params[:do]
    redirect_to(edit_market_path(@market))
  end

  def destroy
    Market.destroy(params[:id])
    redirect_to(markets_url)
  end
end
