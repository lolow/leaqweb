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

class EnergySystemsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html
  respond_to :json, only: [:select]

  # Select an energy system and store it in the session
  def select
    user_session[:current_res_id] = EnergySystem.find_by_id(params["energy_system"]).id
    user_session[:current_sce_id] = nil
    respond_to do |format|
      format.html {redirect_to root_path}
      format.js {render :json => user_session[:current_res_id].to_json}
    end
  end

  def new
    respond_with(@energy_system = EnergySystem.new)
  end

  def create
    respond_with(@energy_system = EnergySystem.create(params[:energy_system]))
  end

  def show
    redirect_to root_path
  end

  def destroy
    EnergySystem.find(params[:id]).destroy
    redirect_to root_path
  end

end
