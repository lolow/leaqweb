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
# NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'etem_solver'

class SolverJob < ActiveRecord::Base

  #TODO clean files
  before_destroy :finalize_etem_solver

  #Relations
  belongs_to :energy_system

  #Validations
  validates :language, presence: true, inclusion: {in: %w{GAMS GMPL}}
  validates :energy_system, presence: true

  #Scopes
  scope :matching_text
  scope :matching_tag

  def solve
    etem_solver.solve(self.energy_system,self.scenarios)
  end

  def etem_solver
    case self.language
      when "GAMS"
        require 'etem_solver_gams'
        EtemSolverGams.new(opts={}, token=self.id)
      when "GMPL"
        require 'etem_solver_gmpl'
        EtemSolverGmpl.new(opts={}, token=self.id)
      else
        EtemSolver.new(opts={}, token=self.id)
    end
  end

  #def file(ext)
  #  etem.file(ext)
  #end

  #def time_used
  #  etem.time_used
  #end

  #def optimal?
  #  etem.optimal?
  #end

  #def has_files?
  #  etem.has_files?
  #end

  #def update_status
  #  complete! if solving? && etem.solved?
  #end

  #def opts
  #  {
  #    first_year: first_year.to_i,
  #    nb_periods: nb_periods.to_i,
  #    period_duration: period_duration.to_i,
  #    language: language,
  #    scenarios: scenarios
  #  }
  #end

  private

  def finalize_etem_solver
    etem_solver.finalize
  end

end