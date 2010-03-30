class Flow < ActiveRecord::Base
  acts_as_identifiable :prefix => "f"
  belongs_to :technology
  has_many :parameter_values
  has_and_belongs_to_many :commodities
  
  def flow_act_of?(technology)
    Parameter.find_by_name("flow_act").parameter_values.
              find(:first,:conditions=>{:technology_id=>technology,:flow_id=>self})
  end
end
