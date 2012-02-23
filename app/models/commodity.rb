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

require 'etem'

class Commodity < ActiveRecord::Base

  #Pretty url
  extend FriendlyId
  friendly_id :name, use: [:slugged]

  #Interfaces
  has_paper_trail
  acts_as_taggable_on :sets

  #Relations
  belongs_to :energy_system
  belongs_to :demand_driver
  has_and_belongs_to_many :flows
  has_and_belongs_to_many :commodity_sets
  has_many :parameter_values, dependent: :delete_all

  #Validations
  validates :name, presence: true,
                   uniqueness:  {scope: :energy_system_id},
                   format: {with: /\A[a-zA-Z\d-]+\z/, message: "Please use only letters, numbers or '-' in name"}

  # Categories [name,value]
  # sets in value has to be sorted by alphabetical order!!
  CATEGORIES = [
      ["Disabled", ""],
      ["Energy carrier [import]", "C,ENC,IMP"],
      ["Energy carrier [export]", "C,ENC,EXP"],
      ["Energy carrier [import+export]", "C,ENC,EXP,IMP"],
      ["Energy carrier [only]", "C,ENC"],
      ["Pollutant", "C,POLL"],
      ["Demand", "C,DEM"]
  ]

  scope :pollutants, tagged_with("POLL")
  scope :energy_carriers, tagged_with("ENC")
  scope :demands, tagged_with("DEM")
  scope :activated, tagged_with("C")
  scope :imports, tagged_with("IMP")
  scope :exports, tagged_with("EXP")
  scope :matching_text, lambda {|text| where(['name LIKE ? OR description LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag, lambda {|tag| tagged_with(tag) if (tag && tag!="" && tag != "null")}
  scope :find_by_list_name, lambda{|list| where(name: list.split(","))}

  def out_flows
    OutFlow.joins(:commodities).where("commodities.id"=>id)
  end

  def in_flows
    InFlow.joins(:commodities).where("commodities.id"=>id)
  end

  def produced_by
    ids = OutFlow.joins(:commodities).where("commodities.id"=>id).select(:technology_id).map{|f|f.technology_id}
    Technology.where(:id=>ids)
  end

  def consumed_by
    ids = InFlow.joins(:commodities).where("commodities.id"=>id).select(:technology_id).map{|f|f.technology_id}
    Technology.where(:id=>ids)
  end

  def activated?
    set_list.include? "C"
  end

  def demand?
    set_list.include? "DEM"
  end

  #return demand_values
  def demand_values(first_year)
    return [] unless set_list.include? "DEM"
    if demand_driver
      dv = parameter_values.of("demand").where(year: first_year).first
      base_year_value = dv ? dv.value : 0
      driver_values = demand_driver.demand_driver_values.order(:year)
      driver_values.collect! { |pv| [pv.year, pv.value] }
      Etem::demand_projection(driver_values, base_year_value, demand_elasticity)
    else
      parameter_values.of("demand").order(:year).collect { |pv| [pv.year, pv.value] }
    end
  end

  def demand_elasticity
    elas = Hash.new(self.default_demand_elasticity)
    values_for('demand_elasticity').each do |pv|
      elas[pv.year.to_i] = pv.value
    end
    elas
  end

  def values_for(parameters)
    parameter_values.of(Array(parameters)).order(:year)
  end

  def to_s
    name
  end

  def duplicate
    c = Commodity.create(:name => next_available_name(Commodity, name),
                         :description => description,
                         :set_list => set_list.join(", "),
                         :demand_driver => demand_driver)
    parameters = signature.keys.select{|k| signature[k] && signature[k].include?("commodity")}
    parameter_values.of(parameters).each do |pv|
      c.parameter_values << ParameterValue.create(pv.attributes)
    end
    c.save
    c
  end

  #return the corresponding set list from the CATEGORIES array
  def matching_set_list
    my_set = self.set_list.sort.join(",")
    s = nil
    CATEGORIES.each do |c|
      if c[1]==my_set
        s = c[1]
        break
      end
    end
    s
  end

end