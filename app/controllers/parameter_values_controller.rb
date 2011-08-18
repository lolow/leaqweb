# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class ParameterValuesController < ApplicationController

  respond_to :json, :only => [:update_pv]

  def update_value
    f = params[:field].split("-")
    value = ParameterValue.update( f.first.to_i, f.last=>params[:value]) ? params[:value] : ""
    render :json => value
  end

end