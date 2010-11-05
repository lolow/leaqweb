# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class TablesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  def index
    @tables = Table.order(:name)
  end

  def show
    redirect_to edit_market_path(Table.find(params[:id]))
  end

  def new
    respond_with(@table = Table.new)
  end

  def duplicate
    @table = Table.find(params[:id]).duplicate_as_new
    respond_to do |format|
      format.html {render :action => "new"}
    end
  end

  def edit
    respond_with(@table = Table.find(params[:id]))
  end

  def create
    respond_with(@table = Table.create(params[:table]))
  end

  def update
    @table = Table.find(params[:id])
    if @table.update_attributes(params[:table])
      redirect_to(@table, :notice => 'Table was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    Table.destroy(params[:id])
    redirect_to(tables_url)
  end
end
