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

class DemandDriversController < ApplicationController

  before_filter :authenticate_user!
  before_filter :check_res!

  respond_to :html, except: :list
  respond_to :json, only:   :list

  def index
  end

  def list
    @demand_drivers, @total_demand_drivers  = filter_list(demand_drivers,%w(name definition))
    render layout: false, :formats => [:json], partial: "list"
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
    respond_with(@demand_driver = DemandDriver.create(params[:demand_driver]))
  end

  def destroy
    DemandDriver.find(params[:id]).destroy
    redirect_to(demand_drivers_url)
  end

  def destroy_all
    DemandDriver.where(id: checkbox_ids).map(&:destroy)
    redirect_to(demand_drivers_url)
  end

  def update
    @demand_driver = DemandDriver.find(params[:id])
    # jeditable fields
    if params[:field]
      f = params[:field].split("-")
      record = DemandDriverValue.find(f[1].to_i)
      attributes = {f[2]=>params[:value]}
      if record.update_attributes(attributes)
        value = params[:value]
      else
        value = ''
      end
      respond_to do |format|
        format.js { render json: value }
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
            format.html { render action: "edit" }
          end
        end
        return
      when "delete_pv"
        ids = @demand_driver.demand_driver_values.map(&:id).select { |i| params["cb#{i}"] }
        ParameterValue.where(id: checkbox_ids).map(&:destroy)
      when "add_pv"
        att = params[:pv]
        att[:parameter] = @demand_driver
        pv = DemandDriverValue.new(att)
        flash[:notice] = 'Demand driver value was successfully added.' if pv.save
    end if params[:do]
    respond_to do |format|
      format.html { redirect_to(edit_demand_driver_path(@demand_driver)) }
    end
  end

  private

  def demand_drivers
    DemandDriver.where(:energy_system_id=>@current_res)
  end

end