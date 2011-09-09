require 'etem_solver'
require 'yaml'

class Solver < ActiveRecord::Base
  include Workflow

  before_destroy :reset

  validate :check_available_slots, :on => :create
  validates :nb_periods,      :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :period_duration, :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :first_year,      :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :language,        :presence => true, :inclusion => {:in => %w(GAMS GLPK)}

  scope :matching_text, lambda {|text| where(['workflow_state LIKE ?'] + ["%#{text}%"]) }
  scope :matching_tag #empty

  # State Machine
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

  def has_files?
    etem.has_files?
  end

  def update_status
    complete! if solving? && etem.solved?
  end

  def opts
    {
      :first_year => first_year.to_i,
      :nb_periods => nb_periods.to_i,
      :period_duration => period_duration.to_i,
      :language => language,
      :scenarios => scenarios
    }
  end

  private

  def etem
    @etem ||= EtemSolver.new(opts=self.opts, token=self.id, pid=self.pid)
  end

  def reset
    etem.reset
  end

  def check_available_slots
    errors.add(:base, "No job slot available") unless Solver.count < 999
  end

end