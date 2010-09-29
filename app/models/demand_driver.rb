class DemandDriver < Parameter
  has_many :commodities
  has_many :parameter_values, :foreign_key => 'parameter_id'

  validates :name, :presence => true, :uniqueness => true

end