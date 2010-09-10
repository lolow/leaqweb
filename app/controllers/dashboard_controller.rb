require 'leaq_archive'
class DashboardController < ApplicationController

  # GET /
  def index
    @nb_commodities = Commodity.count
    @nb_technologies = Technology.count
    @from_time = Time.now
    @last_change = ParameterValue.order(:updated_at).last.updated_at
    @nb_demand_drivers = DemandDriver.count
    @nb_parameter_values = ParameterValue.count
    @log = VestalVersions::Version.order("created_at DESC").limit(25)
  end

  # GET /res/check_db
  def check_db
    @errors = EtemDebug.new.check_everything
  end

  # GET /backup.zip
  def backup
    f = Tempfile.new("backup")
    LeaqArchive.backup(f.path)
    send_file f.path, :type => "application/zip",
                      :url_based_filename => true
    f.close
  end

  # GET /dashboard/restore
  def restore
    LeaqArchive.clean_database
    LeaqArchive.restore(params[:upload]["db"].path)
    redirect_to root_path
  end

end
