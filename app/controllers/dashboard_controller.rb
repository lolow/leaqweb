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

require 'etem_debug'
require 'yaml'

class DashboardController < ApplicationController

  before_filter :authenticate_user!

  def index
    #@nb_commodities = Commodity.count
    #@nb_technologies = Technology.count
    #@nb_flows = Flow.count
    #@nb_combustions = Combustion.count
    #@nb_demand_drivers = DemandDriver.count
    #@nb_parameter_values = ParameterValue.count
    #@last_change = Version.order(:created_at).last
    @energy_systems = EnergySystem.order(:name).all
    #Cleaning
    if Version.all.size > 100
      Version.delete_all ["created_at < ?", 1.week.ago]
    end
  end

  def check_db
    #TODO move debug to energy_system
    @errors = EtemDebug.new.check_everything
  end

  def backup
    #TODO use energy_system_backup
    #f = Tempfile.new("backup")
    #EtemArchive.backup(f.path)
    #send_file f.path, type: "application/zip",
    #                  url_based_filename: true
    #f.close
  end

  def restore
    #TODO use energy_system_backup
    #if params[:upload] && File.exist?(params[:upload]["db"].tempfile.path)
    #  EtemArchive.clean_database
    #  EtemArchive.restore(params[:upload]["db"].tempfile.path)
    #end
    #redirect_to root_path
  end

  def reset
    #TODO use energy_system_backup
    #EtemArchive.clean_database
    #File.open(File.join(Rails.root, 'lib', 'etem', 'default_parameters.yml')) do |f|
    #  YAML::load(f).each do |record|
    #    Parameter.create(record)
    #  end
    #end
    #redirect_to root_path
  end

end
