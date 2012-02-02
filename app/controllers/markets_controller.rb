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

class MarketsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html
  respond_to :json, :only => [:show]

  def index
    @markets = Market.order(:name)
  end

  def list
    @markets, @total_markets  = filter_list(Market,["name","description"])
    render :layout => false, :partial => "list.json"
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

  def destroy_all
    Market.destroy(checkbox_ids)
    redirect_to(markets_url)
  end

  def suggest
    text = params[:term]
    res = Market.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render :json => res.to_json
  end

end
