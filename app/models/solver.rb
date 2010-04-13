class Solver < ActiveRecord::Base

  before_destroy :reset
  validate_on_create :check_available_slots

  MAX_SOLVERS = 1

  # State Machine
  include Workflow
  workflow do
    state :new do
      event :solve, :transitions_to => :solving
    end

    state :solving do
      event :complete, :transitions_to => :solved
    end

    state :solved
  end
  
  def solve
    self.pid = geoecu.solve
    self.save
  end
  
  def log
    geoecu.log
  end

  def file(ext)
    geoecu.file(ext)
  end

  def time_used
    geoecu.time_used
  end

  def optimal?
    geoecu.optimal?
  end
  
  def prepare_results
    geoecu.prepare_results
  end

  def has_files?
    geoecu.has_files?
  end

  def update_status
    complete! if solving? && geoecu.solved?
  end

  private

  def geoecu
    @geoecu ||= GeoecuSolver.new(:token=>self.id, :pid=>self.pid)
  end

  def reset
    geoecu.reset
  end

  def check_available_slots
    errors.add_to_base("No job slot available") unless Solver.count < MAX_SOLVERS
  end
  
end
