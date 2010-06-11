class EtemController < ApplicationController
  def parameters
    ['nb_periods','period_length','base_year'].each do |p|
      if params[p]
        Parameter.find_by_name(p).update_attributes(:default_value=>params[p].to_i)
      else
        params[p] =  Parameter.find_by_name(p).default_value.to_i
      end
    end
    respond_to do |format|
      format.html
    end
  end
end