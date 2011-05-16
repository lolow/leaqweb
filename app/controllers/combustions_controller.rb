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
    @combustions, @total_combustions  = filter_combustion(params)
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
    value = Combustion.update(field[:id], field[:field]=>params[:value]) ? params[:value] : ""
    render :json => value
  end

  private

  def field
    f = params[:field].split("-")
    {
        :id => f.first.to_i,
        :field => f.last
    }
  end

  def filter_combustion(params={})
    combustions = Combustion.includes(:fuel).includes(:pollutant)
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    columns = [nil,"commodities.name","pollutants_combustions.name","value","source"]
    order   = columns[params[:iSortCol_0] ? params[:iSortCol_0].to_i : 0]
    conditions = []
    if params[:sSearch] && params[:sSearch]!=""
      conditions = ['commodities.name LIKE ? OR pollutants_combustions.name LIKE ? OR combustions.source LIKE ?'] + ["%#{params[:sSearch]}%"] * 3
    end
    filter = {:page => current_page,
              :order => "#{order} #{params[:sSortDir_0] || "DESC"}",
              :conditions => conditions,
              :per_page => params[:iDisplayLength]}
    displayed = combustions.paginate filter
    total = combustions.count :conditions => conditions
    return displayed, total
  end

end