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
    if @aggregate.update_attributes(params[:aggregate])
      redirect_to(@aggregate, :notice => 'Aggregate was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    Aggregate.destroy(params[:id])
    redirect_to(aggregate_url)
  end
end
