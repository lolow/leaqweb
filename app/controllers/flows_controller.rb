class FlowsController < ApplicationController

  # GET /flows/1
  # GET /flows/1.js
  def show
    @flow = Flow.find(params[:id])
    flow_hash = {:flow=>{:id=>@flow.id,:commodities=>@flow.commodities}}

    respond_to do |format|
      format.html { redirect_to(technology_path(@flow.technology)) }
      format.js { render :json => flow_hash.to_json }
    end
  end
  
end
