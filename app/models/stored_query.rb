#--
# Copyright (c) 2009-2012, Public Research Center Henri Tudor
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'zip_tools'

class StoredQuery < ActiveRecord::Base

  has_paper_trail

  DISPLAY = %w( pivot_table line_graph area_graph )

  INDEX = { "T" => "Time period",
            "S" => "Time slice",
            "P" => "Processes",
            "C" => "Commodities"}
  AGGREGATES = %w{SUM MEAN}
  VARIABLES  = %w{VAR_OBJINV VAR_OBJFIX VAR_OBJVAR VAR_OBJSAL} +
               %w{CAPACITY ACTIVITY VAR_IMP VAR_EXP VAR_COM VAR_ICAP DEMAND} +
               %w{C_PRICE AGGREGATE COST_IMP}

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :display
  validates_inclusion_of :display, in: DISPLAY, message: "not valid"

  scope :pivot_tables, where(display: "pivot_table")
  scope :line_graphs, where(display: "line_graph")
  scope :matching_text, lambda {|text| where(['name LIKE ?'] + ["%#{text}%"]) }
  scope :matching_tag, lambda {|tag| where(display: tag) if (tag && tag!="" && tag != "null") }

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
        name:      next_available_name(StoredQuery, name),
        aggregate: aggregate,
        variable:  variable,
        columns:   columns,
        rows:      rows,
        filters:   filters,
        display:   display,
        options:   options)
  end

  def self.import(filename)
    ZipTools::readline_zip(filename,StoredQuery) do |row|
      StoredQuery.create(name:      row["name"],
                         aggregate: row["aggregate"],
                         variable:  row["variable"],
                         rows:      row["rows"],
                         columns:   row["columns"],
                         filters:   row["filters"],
                         display:   row["display"],
                         options:   row["options"])
    end
  end

  def self.zip(filename,subset_ids=nil)
    Zip::ZipOutputStream.open(filename) do |zipfile|
      headers = %w{name aggregate variable rows columns filters display options}
      ZipTools::write_csv_into_zip(zipfile,StoredQuery,headers,subset_ids) do |pv,csv|
        csv << pv.attributes.values_at(*headers)
      end
    end
  end

end
