# Copyright (c) 2009-2011, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.
class ApplicationController < ActionController::Base

  protect_from_forgery

  before_filter :layout_info

  protected

  def layout_info
    @title = ["ETEM Luxembourg"]
    @author = "Laurent Drouet"
    @keywords = %w(leaq geoecu ayltp energy air quality)
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

end