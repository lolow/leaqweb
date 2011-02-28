require 'etem_solver'
require 'yaml'

class Solver < ActiveRecord::Base

  before_destroy :reset

  validate :check_available_slots, :on => :create
  validates :nb_periods, :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :period_duration, :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :first_year, :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :language, :presence => true, :inclusion => {:in => %w(GAMS GLPK)}

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

  def opts
    YAML.load(self.options)
  end

  def opts=(hash)
    self.options = hash.to_yaml
  end

  private

  def etem
    @etem ||= EtemSolver.new(token=self.id, pid=self.pid, opts=self.opts)
  end

  def reset
    etem.reset
  end

  def check_available_slots
    errors.add(:base, "No job slot available") unless Solver.count < 999
  end

end