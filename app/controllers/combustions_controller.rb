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

class CombustionsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, except: [:update_value,:list]
  respond_to :json, only:   [:update_value,:list]

  def index
    @combustion = Combustion.new
  end

  def list
    combustions = Combustion
    @combustions, @total_combustions = filter_list(combustions,%w(fuel pollutant value source))
    render layout: false, :formats => [:json], partial: "list"
  end

  def create
    case params[:do]
      when "add_pv"
        @combustion = Combustion.new(params[:combustion])
        if @combustion.save
          flash[:notice]='Combustion coefficient was successfully added.'
        else
          render action: "index"
          return
        end
      when "delete_pv"
        Combustion.where(id: checkbox_ids).map(&:destroy)
        flash[:notice]='Combustion coefficients have been deleted.'
    end
    redirect_to(combustions_path)
  end

  def update_value
    f = params[:field].split("-")
    value = Combustion.update(f.first.to_i, f.last=>params[:value]) ? params[:value] : ""
    render :json => value
  end

  def upload
    if params[:import] && File.exist?(params[:import]["combustion"].tempfile.path)
      Combustion.import(params[:import]["combustion"].tempfile.path)
      redirect_to(combustions_url, notice: 'File has been imported.')
    else
      redirect_to(combustions_url, notice: 'No file to upload.')
    end
  end

  def zip
    f = Tempfile.new("combustions")
    Combustion.zip(f.path,params[:combustions_id])
    send_file f.path, type: "application/zip",
                      filename: "combustions.zip"
  end

end