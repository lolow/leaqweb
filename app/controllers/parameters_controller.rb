class ParametersController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json, :only => [:suggest]

  def suggest
    text = params[:term]
    res = Parameter.where(:type=>nil).order(:name).matching_text(text).limit(10).map(&:name)
    res << "..." if res.size==10
    render :json => res.to_json
  end

end