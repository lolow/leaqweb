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

class ScenariosController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, except: [:suggest,:list]
  respond_to :json, only:   [:suggest,:list]

  def index
  end

  def new
    respond_with(@scenario = Scenario.new)
  end

  def show
    redirect_to edit_scenario_path(Scenario.find(params[:id]))
  end

  def list
    @scenarios, @total_scenarios = filter_list(Scenario,["name"])
    render layout: false, partial: "list.json"
  end

  def edit
    respond_with(@scenario = Scenario.find(params[:id]))
  end

  def create
    respond_with(@scenario = Scenario.create(params[:scenario]))
  end

  def update
    @scenario = Scenario.find(params[:id])
    if @scenario.update_attributes(params[:scenario])
      redirect_to(@scenario, notice: 'Scenario was successfully updated.')
    else
      render action: "edit"
    end
  end

  def destroy
    Scenario.find(params[:id]).destroy
    redirect_to(scenarios_url)
  end

  def destroy_all
    Scenario.where(id: checkbox_ids).map(&:destroy)
    redirect_to(scenarios_url)
  end

  def suggest
    text = params[:term]
    res = Scenario.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size == 10
    render json: res.to_json
  end

end
