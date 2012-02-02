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

class AggregatesController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html
  respond_to :json, :only => [:show, :suggest]

  def index
    @aggregates = Aggregate.order(:name)
  end

  def list
    @aggregates, @total_aggregates  = filter_list(Aggregate,["name","description"])
    render :layout => false, :partial => "list.json"
  end

  def show
    @aggregate = Aggregate.find(params[:id])
    respond_to do |format|
      format.html { redirect_to edit_aggregate_path(@aggregate) }
      format.js { render :json => {:aggregate=>{:id=>@aggregate.id, :commodities=>@aggregate.commodities}}.to_json }
    end
  end

  def new
    respond_with(@aggregate = Aggregate.new)
  end

  def edit
    respond_with(@aggregate = Aggregate.find(params[:id]))
  end

  def create
    respond_with(@aggregate = Aggregate.create(params[:aggregate]))
  end

  def update
    @aggregate = Aggregate.find(params[:id])
    case params[:do]
      when "update_commodities"
        @aggregate.commodities = Commodity.find_by_list_name(params[:commodities])
        flash[:notice] = 'Aggregate was successfully created.' if @aggregate.save
      when "update"
        @aggregate.update_attributes(params[:aggregate])
        respond_with(@aggregate)
        return
      when "delete_pv"
        ParameterValue.destroy(checkbox_ids)
      when "add_pv"
        att = params[:pv]
        att[:parameter] = Parameter.find_by_name(att[:parameter])
        att[:commodity] = Commodity.find_by_name(att[:commodity]) if att[:commodity]
        att[:aggregate] = @aggregate
        pv = ParameterValue.new(att)
        flash[:notice] = 'Parameter value was successfully added.' if pv.save
    end if params[:do]
    redirect_to(edit_aggregate_path(@aggregate))
  end

  def destroy
    Aggregate.destroy(params[:id])
    redirect_to(aggregates_url)
  end

  def destroy_all
    Aggregate.destroy(checkbox_ids)
    redirect_to(aggregates_url)
  end

  def suggest
    text = params[:term]
    res = Aggregate.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render :json => res.to_json
  end

end
