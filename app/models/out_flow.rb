class OutFlow < Flow
  has_many :parameter_values, :dependent => :delete_all
end