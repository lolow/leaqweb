require 'etem'
class StoredQuery < ActiveRecord::Base
  include Etem

  versioned

  validates :name, :presence => true, :uniqueness => true

  def digest_filter
    filters.split('&').collect { |term|
      term = term.split(" ", 3)
      condition = Hash.new
      condition[:not] = term.first.first=="!" ? "not " : ""
      condition[:variable] = term[0].gsub('!', '').strip
      break unless term[1].index("%in%")
      if term[2].strip.index("grep('^")==0
        condition[:func] = "start with"
        condition[:arg] = term[2].strip.split("'")[1][1..-1]
      elsif term[2].strip.index("grep('")==0
        condition[:func] = "contain"
        condition[:arg] = term[2].strip.split("'")[1]
      elsif term[2].strip.index("c('")==0
        condition[:func] = "belong to"
        condition[:arg] = term[2].scan(/'[a-zA-Z\d-]+'/).collect { |w| w[1..-2] }.join(",")
      end
      condition
    }
  end

  def unused
    INDEX.keys - rows.split('+') - columns.split('+')
  end

  def duplicate_as_new
    StoredQuery.new(
        :name => next_available_name(StoredQuery, name),
        :aggregate => aggregate,
        :variable => variable,
        :columns => columns,
        :rows => rows,
        :filters => filters)
  end

end