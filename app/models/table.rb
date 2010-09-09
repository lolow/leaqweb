class Table < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name

  AGGREGATES = %w{SUM MEAN}
  VARIABLES = %w{VAR_OBJINV VAR_OBJFIX VAR_OBJVAR VAR_OBJSAL} +
              %w{CAPACITY ACTIVITY VAR_IMP VAR_EXP VAR_COM VAR_ICAP DEMAND} +
              %w{C_PRICE}
  INDEX = { "T" => "Time period",
            "S" => "Time slice",
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
        condition[:arg] = term[2].scan(/'[a-zA-Z\d-]+'/).collect{|w|w[1..-2]}.join(",")
      end
      condition
    }
  end

  def unused
    INDEX.keys - rows.split('+') - columns.split('+')
  end

      def clone_from(model)
      model.attributes.each {|attr, value| eval("self.#{attr}= model.#{attr}")}
    end

  def duplicate_as_new
    table = Table.new
    name = self.name + " 01"
    while Table.find_by_name(name)
      name.succ!
    end
    attributes = { :name => name,
                   :aggregate => self.aggregate,
                   :variable => self.variable,
                   :columns => self.columns,
                   :rows => self.rows,
                   :filters => self.filters
    }
    table.attributes = attributes
    table
  end

end