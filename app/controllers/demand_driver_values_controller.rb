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

class DemandDriverValuesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :check_res!

  respond_to :html, only: [:index]
  respond_to :json, only: [:update_pv,:destroy_all,:create]

  def index
  end

  def create

    params[:ddv].keys.each{|k| params[:ddv][k] = params[:ddv][k].strip }
    pv = DemandDriverValue.create(params[:pv])

    render :json => "ok"
  end

  def destroy_all
    DemandDriverValue.where(id: checkbox_ids).map(&:destroy)
    render json: "ok"
  end

  def update_value
    f = params[:field].split("-")
    value = DemandDriverValue.update( f.first.to_i, f.last => params[:value]) ? params[:value] : ""
    render json: value
  end

end