class DemandDriver < Parameter
  has_many :commodities

  scope :matching_text, lambda {|text| where(['name LIKE ? OR definition LIKE ?'] + ["%#{text}%"] * 2) }
  scope :matching_tag, lambda {|tag| tagged_with(tag) if (tag && tag!="" && tag != "null")}

end