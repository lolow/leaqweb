# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class AggregatesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  def index
    @aggregates = Aggregate.order(:name)
  end

  def show
    redirect_to edit_aggregate_path(Aggregate.find(params[:id]))
  end

  def new
    respond_with(@aggregate = Aggregate.new)
  end

  def edit
    respond_with(@aggregate = Aggregate.find(params[:id]))
  end

  def create
    respond_with(@aggregate = Aggregate.create(params[:aggregate]))
  end

  def update
    @aggregate = Aggregate.find(params[:id])
    case params[:do]
      when "update"
        @aggregate.update_attributes(params[:aggregate])
        respond_with(@aggregate)
        return
      when "delete_pv"
        ParameterValue.destroy(checkbox_ids)
      when "add_pv"
        att = params[:pv]
        att[:parameter] = Parameter.find_by_name(att[:parameter])
        att[:aggregate] = @aggregate
        pv = ParameterValue.new(att)
        flash[:notice] = 'Parameter value was successfully added.' if pv.save
    end if params[:do]
    redirect_to(edit_aggregate_path(@aggregate))
  end

  def destroy
    Aggregate.destroy(params[:id])
    redirect_to(aggregate_url)
  end
end
