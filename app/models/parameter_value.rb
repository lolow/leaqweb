#--
# Copyright (c) 2009-2011, Public Research Center Henri Tudor
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

class ParameterValue < ActiveRecord::Base

  has_paper_trail

  belongs_to :parameter
  belongs_to :technology
  belongs_to :commodity
  belongs_to :aggregate
  belongs_to :flow
  belongs_to :out_flow
  belongs_to :in_flow
  belongs_to :market
  belongs_to :sub_market, :class_name => "Market"
  belongs_to :scenario

  validates :value, :presence => true, :numericality => true
  validates :parameter, :presence => true
  validates :year, :numericality => {:only_integer => true, :minimum => -1}, :allow_nil => true
  validates :time_slice, :inclusion => {:in => %w(AN IN ID SN SD WN WD)}, :allow_nil => true
  validates :scenario, :presence => true

  scope :of, lambda { |names| joins(:parameter).where("parameters.name"=>names).order("parameters.name") }
  scope :technology, lambda { |tech| where(:technology_id=>tech) }

end