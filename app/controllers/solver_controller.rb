class SolverController < ApplicationController
  before_filter :authenticate_user!

  # GET /solver/log
  # GET /solver/log.js
  def log
    respond_to do |format|
      format.html { render :text => current_user.solver.log }
      format.js { render :json => current_user.solver.log.to_json }
    end
  end

end
