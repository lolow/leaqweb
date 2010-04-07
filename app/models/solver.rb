class Solver < ActiveRecord::Base

  belongs_to :user

  before_destroy :clean

  # State Machine
  include Workflow
  workflow do
    state :new do
      event :solve, :transitions_to => :solving
    end

    state :solving do
      event :prepare_results, :transitions_to => :finished
    end

    state :finished do
      event :reset, :transitions_to => :new
    end
  end
  
  def solve
    return halt! unless new?
    instance_solver.solve
  end

  def prepare_results
    return halt! unless solved?
    instance_solver.prepare_results
  end

  def solved?
    instance_solver.solved?
  end
  
  private
  
  def clean
    instance_solver.clean_files
  end

  def instance_solver
    GeoecuSolver.new(:token=>self.id.to_s)
  end

end
