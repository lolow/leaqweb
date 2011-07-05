# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

require 'etem_archive'
require 'etem_debug'
require 'yaml'

class DashboardController < ApplicationController

  before_filter :authenticate_user!

  def index
    @nb_commodities = Commodity.count
    @nb_technologies = Technology.count
    @nb_flows = Flow.count
    @nb_combustions = Combustion.count
    @nb_demand_drivers = DemandDriver.count
    @nb_parameter_values = ParameterValue.count
    @last_change = Version.order(:created_at).last
    #Cleaning
    if Version.all.size > 100
      Version.delete_all ["created_at < ?", 1.week.ago]
    end
  end

  def check_db
    @errors = EtemDebug.new.check_everything
  end

  def backup
    f = Tempfile.new("backup")
    EtemArchive.backup(f.path)
    send_file f.path, :type => "application/zip",
              :url_based_filename => true
    f.close
  end

  def restore
    if params[:upload] && File.exist?(params[:upload]["db"].tempfile.path)
      EtemArchive.clean_database
      EtemArchive.restore(params[:upload]["db"].tempfile.path)
    end
    redirect_to root_path
  end

  def reset
    EtemArchive.clean_database
    File.open(File.join(Rails.root, 'lib', 'etem', 'default_parameters.yml')) do |f|
      YAML::load(f).each do |record|
        Parameter.create(record)
      end
    end
    redirect_to root_path
  end

end
