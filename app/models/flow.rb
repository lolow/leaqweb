class Flow < ActiveRecord::Base

  belongs_to :technology
  has_many :parameter_values, :dependent => :delete_all
  has_and_belongs_to_many :commodities

  def flow_act_of?(technology)
    Parameter.find_by_name("flow_act").parameter_values.where("technology_id=? AND flow_id=?", technology, self).first
  end

  def pollutant?
    self.class==OutFlow && self.commodities.size == 1 && self.commodities.first.pollutant?
  end

  def pid
    "f#{id}"
  end
end
