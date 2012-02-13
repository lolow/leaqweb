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

require 'etem'

class ApplicationController < ActionController::Base

  protect_from_forgery

  before_filter :layout_info
  before_filter :save_or_clear_session

  protected

  def layout_info
    @title       = "ETEMboard"
    @author      = "Laurent Drouet"
    @keywords    = %w(energy system model optimization lp gams gmpl etem markal times)
    @description = "ETEM web interface"
  end

  def save_or_clear_session
    if controller_name.eql?('sessions') and action_name.eql?('destroy')
      request.reset_session
    end
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

  def filter_list(active_record,columns=[])
    current_page = (params[:iDisplayStart].to_i/params[:iDisplayLength].to_i rescue 0) + 1
    order        = params[:iSortCol_0] ? columns[params[:iSortCol_0].to_i-1] : nil
    info = {:page => current_page, :per_page => params[:iDisplayLength].to_i}
    info[:order] = "#{order} #{params[:sSortDir_0] || "DESC"}" if order
    total = active_record.matching_text(params[:sSearch]).matching_tag(params[:set]).count
    if (current_page - 1) * params[:iDisplayLength].to_i > total
      info[:page] = (total/params[:iDisplayLength].to_i rescue 0) + 1
    end
    displayed = active_record.matching_text(params[:sSearch]).matching_tag(params[:set]).paginate(info)
    return displayed, total
  end

  private

    # Finds the EnergySystem with the ID stored in the session
    # with the key :current_res_id
    def current_res
      @current_res ||= session[:current_res_id] && EnergySystem.find(session[:current_res_id])
    end

end