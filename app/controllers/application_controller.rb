# Copyright (c) 2009-2010, Laurent Drouet. This file is
# licensed under the Affero General Public License version 3. See
# the COPYRIGHT file.

class ApplicationController < ActionController::Base
  
  protect_from_forgery

  before_filter :layout_info
  
protected

  def layout_info
    @title         = %w(LEAQ)
    @author        = "Laurent Drouet"
    @keywords      = %w(leaq geoecu ayltp energy air quality)
    @description   = "LEAQ web interface"
  end

end