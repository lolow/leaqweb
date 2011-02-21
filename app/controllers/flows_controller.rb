# Copyright (c) 2009-2011, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class FlowsController < ApplicationController
  before_filter :authenticate_user!

  def show
    @flow = Flow.find(params[:id])
    flow_hash = {:flow=>{:id=>@flow.id, :commodities=>@flow.commodities}}

    respond_to do |format|
      format.html { redirect_to(technology_path(@flow.technology)) }
      format.js { render :json => flow_hash.to_json }
    end
  end

  def create
    coms = Commodity.find_by_list_name(params[:commodities])
    if coms.size >0
      case params[:type]
        when 'In flow'
          f = InFlow.new(:technology_id=>params[:technology_id])
        when 'Out flow'
          f = OutFlow.new(:technology_id=>params[:technology_id])
      end
      f.commodities = coms
      flash[:notice] = 'Flow was successfully created.' if f.save
    end
    respond_to do |format|
      format.js { render :json => "".to_json }
    end
  end

  def update
    @flow = Flow.find(params[:id])
    coms = Commodity.find_by_list_name(params[:commodities])
    @flow.commodities = coms if coms.size >0
    respond_to do |format|
      format.js { render :json => "".to_json }
    end
  end

end