# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class ApplicationController < ActionController::Base

  protect_from_forgery

  before_filter :layout_info

  protected

  def layout_info
    @title       = ["ETEM Luxembourg"]
    @author      = "Laurent Drouet"
    @keywords    = %w(leaq geoecu ayltp energy air quality)
    @description = "LEAQ web interface"
  end

  def checkbox_ids
    params.keys.select{|x| x=~/cb\d+/ }.collect{|x| x[2..-1].to_i }
  end

  def last_visited(active_model)
    active_model.where(:id=>Array(session["last-#{active_model}"]))
  end

  def new_visit(active_model, id)
    list = Array(session["last-#{active_model}"])
    list.unshift(id) unless list.include? id
    session["last-#{active_model}"] = list[0, 10]
  end

  def build_filter(params={})
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    columns = [nil,"name","description"]
    order   = columns[params[:iSortCol_0] ? params[:iSortCol_0].to_i : 0]
    conditions = []
    if params[:sSearch] && params[:sSearch]!=""
      conditions = ['name LIKE ? OR description LIKE ?'] + ["%#{params[:sSearch]}%"] * 2
    end
    filter = {:page => current_page,
              :order => "#{order} #{params[:sSortDir_0] || "DESC"}",
              :conditions => conditions,
              :per_page => params[:iDisplayLength]}
  end

end