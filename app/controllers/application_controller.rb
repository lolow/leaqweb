class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :first_filter
  
protected

  def first_filter
    @title         = %w(Leaqweb)
    @author        = "Laurent Drouet"
    @keywords      = %w(leaq geoecu ayltp energy air quality)
    @description   = "LEAQ web interface"
  end

end

#TODO
#audit Commodity, Technology, Parameter, ParameterValue, Table