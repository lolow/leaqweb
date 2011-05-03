# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class DemandDriversController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list

  def index
  end

  def list
    @demand_drivers, @total_demand_drivers  = filter_demand_drivers(params)
    render :layout => false, :partial => "list.json"
  end

  def show
    redirect_to edit_demand_driver_path(DemandDriver.find(params[:id]))
  end

  def edit
    @demand_driver = DemandDriver.find(params[:id])
    respond_with(@demand_driver)
  end

  def new
    respond_with(@demand_driver = DemandDriver.new)
  end

  def create
    respond_with(@demand_driver = DemandDriver.new(params[:demand_driver]))
  end

  def destroy
    DemandDriver.destroy(params[:id])
    redirect_to(demand_drivers_url)
  end

  def destroy_all
    DemandDriver.destroy(checkbox_ids)
    redirect_to(demand_drivers_url)
  end

  def update
    @demand_driver = DemandDriver.find(params[:id])
    # jeditable fields
    if params[:field]
      f = params[:field].split("-")
      record = ParameterValue.find(f[1].to_i)
      attributes = {f[2]=>params[:value]}
      if record.update_attributes(attributes)
        value = params[:value]
      else
        value = ''
      end
      respond_to do |format|
        format.js { render :json => value }
      end
      return
    end
    # action on parameter_value
    case params[:do]
      when "update"
        respond_to do |format|
          if @demand_driver.update_attributes(params[:demand_driver])
            flash[:notice] = 'Demand driver was successfully updated.'
            format.html { redirect_to(edit_demand_driver_path(@technology)) }
          else
            format.html { render :action => "edit" }
          end
        end
        return
      when "delete_pv"
        ids = @demand_driver.parameter_values.map(&:id).select { |i| params["cb#{i}"] }
        ParameterValue.destroy(ids)
      when "add_pv"
        att = params[:pv]
        att[:parameter] = @demand_driver
        pv = ParameterValue.new(att)
        flash[:notice] = 'Demand driver value was successfully added.' if pv.save
    end if params[:do]
    respond_to do |format|
      format.html { redirect_to(edit_demand_driver_path(@demand_driver)) }
    end
  end

  private

  def filter_demand_drivers(params={})
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    columns = [nil,"name","definition"]
    order   = columns[params[:iSortCol_0] ? params[:iSortCol_0].to_i : 0]
    conditions = []
    if params[:sSearch] && params[:sSearch]!=""
      conditions = ['name LIKE ? OR definition LIKE ?'] + ["%#{params[:sSearch]}%"] * 2
    end
    filter = {:page => current_page,
              :order => "#{order} #{params[:sSortDir_0] || "DESC"}",
              :conditions => conditions,
              :per_page => params[:iDisplayLength]}
    if params[:set] && params[:set]!="null"
      displayed = DemandDriver.tagged_with(params[:set]).paginate filter
      total = DemandDriver.tagged_with(params[:set]).count :conditions => conditions
    else
      displayed = DemandDriver.paginate filter
      total = DemandDriver.count :conditions => conditions
    end
    return displayed, total
  end

end
