# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class CombustionsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => [:update_value,:list]
  respond_to :json, :only => [:update_value,:list]

  def index
    @combustion = Combustion.new
  end

  def list
    combustions = Combustion.includes(:fuel).includes(:pollutant)
    @combustions, @total_combustions  = filter_list(combustions,["commodities.name","pollutants_combustions.name","value","source"])
    render :layout => false, :partial => "list.json"
  end

  def create
    case params[:do]
      when "add_pv"
        @combustion = Combustion.new(params[:combustion])
        if @combustion.save
          flash[:notice]='Combustion coefficient was successfully added.'
        else
          render :action => "index"
          return
        end
      when "delete_pv"
        Combustion.destroy(checkbox_ids)
        flash[:notice]='Combustion coefficients have been deleted.'
    end
    redirect_to(combustions_path)
  end

  def update_value
    f = params[:field].split("-")
    value = Combustion.update(f.first.to_i, f.last=>params[:value]) ? params[:value] : ""
    render :json => value
  end

end