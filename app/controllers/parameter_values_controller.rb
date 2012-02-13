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

class ParameterValuesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :only => [:index]
  respond_to :json, :only => [:update_pv,:destroy_all,:create]

  def index
  end

  def create

    render :json => "wrong data" unless params[:pv]

    # Clean the fields if necessary
    params[:pv].keys.each{|k|params[:pv][k]=params[:pv][k].strip}
    params[:pv][:parameter] = Parameter.find_by_name(params[:pv][:parameter])

    params[:pv][:year] = nil unless params[:pv][:year] && params[:pv][:year].size > 0
    params[:pv][:time_slice] = nil unless params[:pv][:time_slice] && Etem::TIME_SLICES.include?(params[:pv][:time_slice])

    params[:pv][:commodity] = Commodity.find_by_name(params[:pv][:commodity])

    params[:pv][:flow]     = Flow.find_by_id(params[:pv][:flow])
    params[:pv][:in_flow]  = InFlow.find_by_id(params[:pv][:in_flow])
    params[:pv][:out_flow] = OutFlow.find_by_id(params[:pv][:out_flow])

    params[:pv][:commodity_set] = CommoditySet.find_by_name(params[:pv][:commodity_set])

    params[:pv][:technology_set] = TechnologySet.find_by_name(params[:pv][:technology_set])
    params[:pv][:technology_subset] = TechnologySet.find_by_name(params[:pv][:technology_subset])

    params[:pv][:scenario] = Scenario.find_by_name(params[:pv][:scenario])

    pv = ParameterValue.create(params[:pv])

    render :json => "ok"
  end

  def destroy_all
    ParameterValue.where(:id=>checkbox_ids).map(&:destroy)
    render :json => "ok"
  end

  def list
    columns = [nil,"parameters.name","year","time_slice","technologies.name","commodities.name",
               nil,nil,nil,"commodity_sets.name","technology_sets.name",nil,"value","source",
               "scenarios.name"]
    order        = params[:iSortCol_0] ? columns[params[:iSortCol_0].to_i] : nil
    parameter_values = ParameterValue.includes(:parameter).where("parameters.type"=>nil)
    @totalpv = parameter_values.count # Exclude demand_drivers
    parameter_values = parameter_values.includes(:technology)
    parameter_values = parameter_values.includes(:commodity)
    parameter_values = parameter_values.includes(:commodity_set)
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