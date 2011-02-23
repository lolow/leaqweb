# Copyright (c) 2009-2011, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class ParameterValuesController < ApplicationController

  respond_to :json, :only => [:update]

  def update
    value = ParameterValue.update(field[:id], field[:field]=>params[:value]) ? params[:value] : ""
    render :json => value
  end

  private

  def field
    f = params[:field].split("-")
    {:id => f.first.to_i,:field => f.last}
  end

end