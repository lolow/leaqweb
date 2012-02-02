#--
# Copyright (c) 2009-2012, Public Research Center Henri Tudor
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'etem_solver'
require 'yaml'

class Solver < ActiveRecord::Base
  include Workflow

  before_destroy :reset

  LANGUAGES = %w{GAMS GMPL}

  validates :nb_periods,      :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :period_duration, :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :first_year,      :presence => true, :numericality => {:only_integer => true, :minimum => -1}
  validates :language,        :presence => true, :inclusion => {:in => LANGUAGES}

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

end