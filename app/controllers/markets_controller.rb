# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class MarketsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  def index
    @markets = Market.order(:name)
  end

  def show
    redirect_to edit_market_path(Market.find(params[:id]))
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
    if @market.update_attributes(params[:market])
      redirect_to(@market, :notice => 'Market was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    Market.destroy(params[:id])
    redirect_to(markets_url)
  end
end
