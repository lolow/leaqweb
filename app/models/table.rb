class Table < ActiveRecord::Base

  AGGREGATES = %w{SUM MEAN}
  VARIABLES = %w{VAR_OBJINV VAR_OBJFIX VAR_OBJVAR VAR_OBJSAL CAPACITY ACTIVITY VAR_IMP VAR_EXP VAR_COM VAR_ICAP}

  def detailed_filter
    filters.split('&').collect { |term|
      term = term.split(" ",3)
      p term
      condition = Hash.new
      condition[:not] = true if term[0][0]=="!"
      condition[:var] = term[0].gsub('!','')
      break unless term[1].index("%in%")
      if term[2].strip.index("grep('^")==0
        condition[:func] = :start_with
        condition[:arg] = term[2].strip.split("'")[1][1..-1]
      elsif term[2].strip.index("grep('")==0
        condition[:func] = :contains
        condition[:arg] = term[2].strip.split("'")[1]
      elsif term[2].strip.index("c('")==0
        condition[:func] = :list
        condition[:arg] = term[2].scan(/'\w+'/).collect{|w|w[1..-2]}.join(",")
      end
      condition
    }
  end

end
