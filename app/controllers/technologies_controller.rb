# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class TechnologiesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => [:list, :index]

  def index
    respond_to do |format|
      format.html { @last_visited = last_visited(Technology) }
      format.js do
        technologies = Technology.order(:name).select(:name)
        if params[:filter] && params[:filter]!=""
          technologies = technologies.where(["name LIKE ?", "%#{params[:filter]}%"])
        end
        render :json => {"tech"  => technologies.map(&:name)
                        }.to_json
      end
    end
  end

  def list
    @technologies, @total_technologies  = filter_list(Technology,["name","description"])
    render :layout => false, :partial => "list.json"
  end

  def show
    redirect_to edit_technology_path(Technology.find(params[:id]))
  end

  def new
    respond_with(@technology = Technology.new)
  end

  def edit
    new_visit(Technology, params[:id])
    respond_with(@technology = Technology.find(params[:id]))
  end

  def create
    respond_with(@technology = Technology.create(params[:technology]))
  end

  def duplicate
    @technology = Technology.find(params[:id]).duplicate
    redirect_to(edit_technology_path(@technology))
  end

  def update
    @technology = Technology.find(params[:id])
    case params[:do]
      when "preprocess_input_output"
        @technology.preprocess_input_output
      when "update"
        if @technology.update_attributes(params[:technology])
          flash[:notice] = "Technology was successfully updated. #{undo_link(@technology)}"
          redirect_to(edit_technology_path(@technology))
        else
          render :action => "edit"
        end
        return
      when "delete_pv"
        ids = @technology.parameter_values.map(&:id).select { |i| params["cb#{i}"] }
        ParameterValue.destroy(ids)
      when "combustion_flo"
        in_flow_ids = @technology.in_flows.map(&:id).select { |i| params["f#{i}"] }
        in_flow_ids << @technology.in_flows.first.id
        out_flow_ids = @technology.out_flows.map(&:id).select { |i| params["f#{i}"] }
        out_flow_ids.each do |f|
          in_flow = InFlow.find(in_flow_ids.first)
          out_flow = OutFlow.find(f)
          coef = @technology.combustion_factor(in_flow, out_flow)
          param = Parameter.find_by_name("eff_flo")
          pv = ParameterValue.where("parameter_id=? AND in_flow_id=? AND out_flow_id=?", param, in_flow.id, out_flow.id).first
          if pv
            puts "update"
            pv.update_attributes(:value=>coef,
                                 :source=>"Combustion coefficients")
          else
            puts "create"
            ParameterValue.create(:parameter=>param,
                                  :technology=>@technology,
                                  :in_flow=>in_flow,
                                  :out_flow=>out_flow,
                                  :value=>coef,
                                  :source=>"Combustion coefficients")
          end
        end
      when "add_pv"
        att = params[:pv]
        att[:flow] = Flow.find(att[:flow].to_i) if att[:flow]
        att[:in_flow] = InFlow.find(att[:in_flow].to_i) if att[:in_flow]
        att[:out_flow] = OutFlow.find(att[:out_flow].to_i) if att[:out_flow]
        att[:parameter] = Parameter.find_by_name(att[:parameter])
        att[:commodity] = Commodity.find_by_name(att[:commodity]) if att[:commodity]
        att[:technology] = @technology
        pv = ParameterValue.new(att)
        flash[:notice] = "Parameter value was successfully added. #{undo_link(pv)}" if pv.save
      when "set_act_flo"
        ids = @technology.flows.map(&:id).select { |i| params["f#{i}"] }
        @technology.flow_act=Flow.find(ids[0]) if ids.size>0
      when "delete_flo"
        ids = @technology.flows.map(&:id).select { |i| params["f#{i}"] }
        Flow.destroy(ids)
    end if params[:do]
    redirect_to(edit_technology_path(@technology))
  end

  def destroy_all
    Technology.destroy(checkbox_ids)
    redirect_to(technologies_url)
  end

  def destroy
    Technology.destroy(params[:id])
    redirect_to(technologies_url)
  end

  private

  def undo_link(object)
    view_context.link_to("(undo)", revert_version_path(object.versions.scoped.last), :method => :post)
  end

end