class InFlow < Flow
  belongs_to :technology
  has_many :parameter_values
end