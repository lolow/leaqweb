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

class Combustion < ActiveRecord::Base

  #Interfaces
  has_paper_trail

  #Validations
  validates :value, presence: true, numericality: true

  #Scopes
  scope :matching_text, lambda { |text| where(['combustions.pollutant LIKE ? OR combustions.fuel LIKE ? OR combustions.source LIKE ?'] + ["%#{text}%"] * 3) }
  scope :matching_tag #empty because not taggable

  def self.import(filename)
    ZipTools::readline_zip(filename, StoredQuery) do |row|
      Combustion.create({fuel: row["fuel"],
                         pollutant: row["pollutant"],
                         value: row["value"],
                         source: row["source"]})
    end
  end

  def self.zip(filename, subset_ids=nil)
    Zip::ZipOutputStream.open(filename) do |zipfile|
      headers = %w{fuel pollutant value source}
      ZipTools::write_csv_into_zip(zipfile, Combustion, headers, subset_ids) do |pv, csv|
        csv << pv.attributes.values_at(*headers)
      end
    end
  end

end
