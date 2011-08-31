require 'etem'
class StoredQuery < ActiveRecord::Base
  include Etem

  has_paper_trail

  DISPLAY = %w( pivot_table line_graph area_graph )

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :display
  validates_inclusion_of :display, :in => DISPLAY, :message => "not valid"

  scope :pivot_tables, where(:display=>"pivot_table")
  scope :line_graphs, where(:display=>"line_graph")
  scope :matching_text, lambda {|text| where(['name LIKE ?'] + ["%#{text}%"]) }
  scope :matching_tag, lambda {|tag| where(:display=>tag) if (tag && tag!="" && tag != "null") }


  def digest_filter
    filters.split('&').collect { |term|
      term = term.split(" ", 3)
      condition = Hash.new
      condition[:not] = term.first.first=="!" ? "not " : ""
      condition[:variable] = term[0].gsub('!', '').strip
      break unless term[1].index("%in%")
      if term[2].strip.index("grep('")==0
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
        :filters => filters,
        :display => display,
        :options => options)
  end

end
