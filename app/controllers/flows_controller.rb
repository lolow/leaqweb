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

class FlowsController < ApplicationController
  before_filter :authenticate_user!

  def show
    @flow = Flow.find(params[:id])
    respond_to do |format|
      format.html { redirect_to(technology_path(@flow.technology)) }
      format.js { render json: {flow: {id: @flow.id, commodities: @flow.commodities}}.to_json }
    end
  end

  def create
    commodities = Commodity.find_by_list_name(params[:commodities])
    if commodities.size >0
      f = case params[:type]
        when 'In flow'
          InFlow.new(technology_id: params[:technology_id])
        when 'Out flow'
          OutFlow.new(technology_id: params[:technology_id])
        else
          nil
      end
      f.commodities = commodities
      flash[:notice] = 'Flow was successfully created.' if f.save
    end
    respond_to do |format|
      format.js { render json: "".to_json }
    end
  end

  def update
    @flow = Flow.find(params[:id])
    commodities = Commodity.find_by_list_name(params[:commodities])
    @flow.commodities = commodities if commodities.size > 0
    respond_to do |format|
      format.js { render json: "".to_json }
    end
  end

end