class DemandDriver < Parameter
  has_many :commodities
  has_many :parameter_values, :foreign_key => 'parameter_id'
  
  validates_presence_of :name
  validates_uniqueness_of :name

end