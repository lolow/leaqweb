# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class CombustionsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html, :except => [:update]
  respond_to :json, :only => [:update]

  def index
    @combustions = combustions_all
    @combustion  = Combustion.new
  end

  def create
    case params[:do]
    when "create"
      @combustion = Combustion.new(params[:combustion])
      if @combustion.save
        flash[:notice]='Combustion coefficient was successfully added.'
      else
        @combustions = combustions_all
        render :action => "index"
        return
      end
    when "delete"
      Combustion.destroy(checkbox_ids)
      flash[:notice]='Combustion coefficients has been deleted.'
    end
    redirect_to(combustions_path)
  end

  def update
    value = Combustion.update(field[:id],field[:field]=>params[:value]) ? params[:value] : ""
    render :json => value
  end

  private

  def combustions_all
    Combustion.includes(:fuel).includes(:pollutant).all
  end

  def field
    f = params[:field].split("-")
    return {
      :id    => f.first.to_i,
      :field => f.last
    }
  end

end