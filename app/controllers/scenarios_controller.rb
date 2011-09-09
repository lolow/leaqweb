class ScenariosController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => [:suggest,:list]
  respond_to :json, :only => [:suggest,:list]

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
    render :layout => false, :partial => "list.json"
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
      redirect_to(@scenario, :notice => 'Scenario was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    Scenario.destroy(params[:id])
    redirect_to(scenarios_url)
  end

  def destroy_all
    Scenario.destroy(checkbox_ids)
    redirect_to(scenarios_url)
  end

  def suggest
    text = params[:term]
    res = Scenario.order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render :json => res.to_json
  end

end
