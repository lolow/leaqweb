class WelcomeController < ApplicationController
  def index
  end

  def solve
    s = LeaqSolver.new
    s.solve
  end

end
