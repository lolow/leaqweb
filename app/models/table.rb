class Table < ActiveRecord::Base

  def detailed_filter
    filters.split('&').collect { |term|
      term = term.split(" ",3)
      condition = Hash.new
      condition[:not] = true if term[0][0]=="!"
      condition[:var] = term[0].gsub('!','')
      if term[2].strip.index("grep('^")==0
        condition[:func] = :start_with
        condition[:arg] = zz[2].strip.split("'")[1][1..-1]
      elsif term[2].strip.index("grep('")==0
        condition[:func] = :contains
        condition[:arg] = term[2].strip.split("'")[1]
      else
        condition[:func] = :list
        condition[:arg] = term[2].scan(/'\w+'/).collect{|w|w[1..-2]}.join(",")
      end
      condition
    }
  end

end
