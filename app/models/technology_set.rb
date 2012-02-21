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

class TechnologySet < ActiveRecord::Base

  #Pretty url
  extend FriendlyId
  friendly_id :name, use: [:slugged]

  #Interfaces
  has_paper_trail
  acts_as_taggable_on :sets

  #Relations
  belongs_to :energy_system
  has_and_belongs_to_many :technologies
  has_many :parameter_values, :dependent => :delete_all

  #Validations
  validates :name, presence: true,
                   uniqueness: true,
                   format: {with: /\A[a-zA-Z\d-]+\z/, message: "Please use only letters, numbers or '-' in name"}

  scope :activated, tagged_with("MARKET")
  scope :matching_text, lambda {|text| where(['name LIKE ? OR description LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag, lambda {|tag| tagged_with(tag) if (tag && tag!="" && tag != "null")}


  def values_for(parameters)
    ParameterValue.of(Array(parameters)).where(technology_set_id: self).order(:year)
  end

end
