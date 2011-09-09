# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class ParameterValuesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :only => [:index]
  respond_to :json, :only => [:update_pv,:destroy_all,:create]

  def index
  end

  def create

    render :json => "wrong data" unless params[:pv]

    # Clean the fields if necessary
    params[:pv][:parameter] = Parameter.find_by_name(params[:pv][:parameter])

    params[:pv][:year] = nil unless params[:pv][:year] && params[:pv][:year].size > 0
    params[:pv][:time_slice] = nil unless params[:pv][:time_slice] && Etem::TIME_SLICES.include?(params[:pv][:time_slice])

    params[:pv][:commodity] = Commodity.find_by_name(params[:pv][:commodity])

    params[:pv][:flow]     = Flow.find_by_id(params[:pv][:flow])
    params[:pv][:in_flow]  = InFlow.find_by_id(params[:pv][:in_flow])
    params[:pv][:out_flow] = OutFlow.find_by_id(params[:pv][:out_flow])

    params[:pv][:aggregate] = Aggregate.find_by_name(params[:pv][:aggregate])

    params[:pv][:market] = Market.find_by_name(params[:pv][:market])
    params[:pv][:sub_market] = Market.find_by_name(params[:pv][:sub_market])

    params[:pv][:scenario] = Scenario.find_by_name(params[:pv][:scenario])

    pv = ParameterValue.create(params[:pv])

    render :json => "ok"
  end

  def destroy_all
    ParameterValue.destroy(checkbox_ids)
    render :json => "ok"
  end

  def list
    columns = [nil,"parameters.name","year","time_slice","technologies.name","commodities.name",
               nil,nil,nil,"aggregates.name","markets.name",nil,"value","source",
               "scenarios.name"]
    order        = params[:iSortCol_0] ? columns[params[:iSortCol_0].to_i] : nil
    parameter_values = ParameterValue.includes(:parameter).where("parameters.type"=>nil)
    @totalpv = parameter_values.count # Exclude demand_drivers
    parameter_values = parameter_values.includes(:technology)
    parameter_values = parameter_values.includes(:commodity)
    parameter_values = parameter_values.includes(:aggregate)
    parameter_values = parameter_values.includes(:scenario)
    columns.each_index do |i|
      if columns[i] && params["sSearch_#{i}"] && params["sSearch_#{i}"].size > 1
        parameter_values = parameter_values.where(["#{columns[i]} LIKE ?","%"+params["sSearch_#{i}"]+"%"])
      end
    end
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    info = {:page => current_page, :per_page => params[:iDisplayLength]}
    info[:order] = "#{order} #{params[:sSortDir_0] || "DESC"}" if order
    @total = parameter_values.count
    if (current_page - 1 ) * params[:iDisplayLength].to_i > @total
        info[:page] = (total/params[:iDisplayLength].to_i rescue 0) + 1
      end
    @displayed = parameter_values.paginate(info)
    render :layout => false, :partial => "parameter_values.json"
  end

  def update_value
    f = params[:field].split("-")
    value = ParameterValue.update( f.first.to_i, f.last=>params[:value]) ? params[:value] : ""
    render :json => value
  end

end