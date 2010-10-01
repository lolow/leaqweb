# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class TechnologiesController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  def index
    filter = {:page => params[:page],
      :per_page => 30,
      :order => :name}
    if params[:search]
      filter.merge!({:conditions => ['name like ?', "%#{params[:search]}%"]})
    end
    @last_visited = last_visited(Technology)
    @sets_cloud = Technology.tag_counts_on(:sets)
    if params[:set]
      @technologies = Technology.tagged_with(params[:set]).paginate(filter)
    else
      @technologies = Technology.paginate(filter)
    end
  end

  def show
    @technology = Technology.find(params[:id])
    redirect_to edit_technology_path(@technology)
  end

  def new
    @technology = Technology.new
  end

  def edit
    new_visit(Technology,params[:id])
    @technology = Technology.find(params[:id])
  end

  def create
    @technology = Technology.new(params[:technology])
    if @technology.save
      flash[:notice] = 'Technology was successfully created.'
      redirect_to(@technology)
    else
      render :action => "new"
    end
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
        flash[:notice] = 'Technology was successfully updated.'
        redirect_to(edit_technology_path(@technology))
      else
        render :action => "edit"
      end
      return
    when "delete_pv"
      ids = @technology.parameter_values.map(&:id).select{|i|params["cb#{i}"]}
      ParameterValue.destroy(ids)
    when "combustion_flo"
      in_flow_ids = @technology.in_flows.map(&:id).select{|i|params["f#{i}"]}
      in_flow_ids << @technology.in_flows.first.id
      out_flow_ids = @technology.out_flows.map(&:id).select{|i|params["f#{i}"]}
      out_flow_ids.each do |f|
        in_flow = InFlow.find(in_flow_ids.first)
        out_flow = OutFlow.find(f)
        coef = @technology.combustion_factor(in_flow,out_flow)
        param = Parameter.find_by_name("eff_flo")
        pv = ParameterValue.where("parameter_id=? AND in_flow_id=? AND out_flow_id=?",param,in_flow.id,out_flow.id).first
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
      att[:out_flow] = OutFlow.find(att[:out_flow].to_i)  if att[:out_flow]
      att[:parameter] = Parameter.find_by_name(att[:parameter])
      att[:commodity] = Commodity.find_by_name(att[:commodity]) if att[:commodity]
      att[:technology] = @technology
      pv = ParameterValue.new(att)
      flash[:notice] = 'Parameter value was successfully added.' if pv.save
    when "set_act_flo"
      ids = @technology.flows.map(&:id).select{|i|params["f#{i}"]}
      @technology.flow_act=Flow.find(ids[0]) if ids.size>0
    when "delete_flo"
      ids = @technology.flows.map(&:id).select{|i|params["f#{i}"]}
      Flow.destroy(ids)
    end if params[:do]
    redirect_to(edit_technology_path(@technology))
  end

  def destroy
    Technology.destroy(params[:id])
    redirect_to(technologies_url)
  end
end