class Table < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name

  AGGREGATES = %w{SUM MEAN}
  VARIABLES = %w{VAR_OBJINV VAR_OBJFIX VAR_OBJVAR VAR_OBJSAL} +
              %w{CAPACITY ACTIVITY VAR_IMP VAR_EXP VAR_COM VAR_ICAP DEMAND} +
              %w{C_PRICE}
  INDEX = { "T" => "Time period",
            "S" => "Time slice",
            "L" => "Location",
            "P" => "Processes",
            "C" => "Commodities" }.freeze

  def digest_filter
    filters.split('&').collect { |term|
      term = term.split(" ",3)
      condition = Hash.new
      if term.first.first=="!"
        condition[:not] = "not "
      else
        condition[:not] = ""
      end
      condition[:variable] = term[0].gsub('!','').strip
      break unless term[1].index("%in%")
      if term[2].strip.index("grep('^")==0
        condition[:func] = "start with"
        condition[:arg] = term[2].strip.split("'")[1][1..-1]
      elsif term[2].strip.index("grep('")==0
        condition[:func] = "contain"
        condition[:arg] = term[2].strip.split("'")[1]
      elsif term[2].strip.index("c('")==0
        condition[:func] = "belong to"
        condition[:arg] = term[2].scan(/'\w+'/).collect{|w|w[1..-2]}.join(",")
      end
      condition
    }
  end

  def unused
    INDEX.keys - rows.split('+') - columns.split('+')
  end

end