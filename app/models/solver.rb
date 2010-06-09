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
    self.pid = etem.solve
    self.save
  end
  
  def log
    etem.log
  end

  def file(ext)
    etem.file(ext)
  end

  def time_used
    etem.time_used
  end

  def optimal?
    etem.optimal?
  end
  
  def prepare_results
    etem.prepare_results
  end

  def has_files?
    etem.has_files?
  end

  def update_status
    complete! if solving? && etem.solved?
  end

  private

  def etem
    @etem ||= EtemSolver.new(token=self.id, pid=self.pid)
  end

  def reset
    etem.reset
  end

  def check_available_slots
    errors.add_to_base("No job slot available") unless Solver.count < MAX_SOLVERS
  end
  
end