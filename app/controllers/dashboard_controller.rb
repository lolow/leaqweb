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
    @from_time = Time.now
    klasses = [ParameterValue,Parameter,Combustion,Technology,Commodity,Flow]
    last_changes = klasses.collect {|k| k.order(:updated_at).last.updated_at if k.count > 0} 
    last_changes.compact!
    @nb_demand_drivers = DemandDriver.count
    @nb_parameter_values = ParameterValue.count
    @log = VestalVersions::Version.order("created_at DESC").limit(10)
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
    if File.exist?(params[:upload]["db"].tempfile.path)
      EtemArchive.clean_database
      EtemArchive.restore(params[:upload]["db"].tempfile.path)
    end
    redirect_to root_path
  end
  
  def log
    @log = VestalVersions::Version.order("created_at DESC").limit(200)
  end
  
  def reset
    EtemArchive.clean_database
    File.open(File.join(Rails.root,'lib','etem','default_parameters.yml')) do |f|
      YAML::load(f).each do |record|
        Parameter.create(record)
      end
    end
    redirect_to root_path
  end

end