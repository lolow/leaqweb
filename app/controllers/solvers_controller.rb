# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

require 'etem_debug'
require 'etem'
require 'yaml'

class SolversController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, :except => :list
  respond_to :json, :only => :list

  USER_OPTION = [:nb_periods, :period_duration, :first_year, :language]

  respond_to :html

  def index
    Solver.all.map(&:update_status)
  end

  def list
    @solvers, @total_solvers = filter_list(Solver)
    render :layout => false, :partial => "list.json"
  end

  def new
    @solver = Solver.new
    USER_OPTION.each do |attr|
      @solver[attr] = Etem::DEF_OPTS[attr]
    end
  end

  def create
    @solver = Solver.create(params[:solver])
    @solver.opts = {
        :first_year => params[:solver][:first_year].to_i,
        :nb_periods => params[:solver][:nb_periods].to_i,
        :period_duration => params[:solver][:period_duration].to_i,
        :language => params[:solver][:language]
    }
    if @solver.save
      flash[:notice] = 'Solver has successfully started.'
      @solver.opts = {
        :first_year => @solver[:first_year].to_i,
        :nb_periods => @solver[:nb_periods].to_i,
        :period_duration => @solver[:period_duration].to_i,
        :language => @solver[:language]
      }
      @solver.solve!
      redirect_to(@solver)
    else
      p @solver.errors
      render :action => "new"
    end
  end

  def show
    @result_sets = ResultSet.all
    @solver = Solver.find(params[:id])
    @solver.update_status
    @refresh = @solver.solving?
    respond_with(@solver)
  end

  def destroy
    Solver.destroy(params[:id])
    redirect_to(solvers_path)
  end

  def destroy_all
    Solver.destroy(checkbox_ids)
    redirect_to(solvers_path)
  end

  def run
  end

end
