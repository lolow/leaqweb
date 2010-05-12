class WelcomeController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]

  def index
  end

  # GET /welcome/backup
  def backup
    f = Tempfile.new("backup")
    LeaqArchive.backup(f.path)
    send_file f.path, :type => "application/zip",
                      :url_based_filename => true
    f.close
  end

  # GET /welcome/restore
  def restore
    LeaqArchive.clean_database
    LeaqArchive.restore(params[:upload]["db"].path)
    redirect_to root_path
  end

end
