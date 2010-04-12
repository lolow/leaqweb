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
    geoecu.log.sub('ENDSOLVER\n','')
  end

  private

  def geoecu
    @geoecu ||= GeoecuSolver.new(:token=>self.id, :pid=>self.pid)
  end

  def reset
    geoecu.reset
  end

  def check_available_slots
    errors.add_to_base("No slot available") unless Solver.count < MAX_SOLVERS
  end
  
end
