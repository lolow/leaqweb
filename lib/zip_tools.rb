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
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'csv'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'benchmark'

module ZipTools

  def self.write_csv_into_zip(zipfile, active_record, headers, subset_ids=nil)
    puts "-- #{active_record.name}"
    time = Benchmark.measure {
      zipfile.put_next_entry(active_record.name)
      text = CSV.generate do |csv|
        csv << headers
        if subset_ids
          res = active_record.where(:id =>subset_ids)
        else
          res = active_record.all
        end
        res.each {|o| yield(o,csv)}
      end
      # zipfile.print(text) is buggy in ruby 1.9
      # the following line replaces it
      zipfile << text << $\.to_s
    }
    puts "   -> %.4fs" % time.real
  end

  def self.readline_zip(zipfile,active_record)
    puts "-- #{active_record.name}"
    time = Benchmark.measure {
      active_record.transaction {
        Zip::ZipInputStream::open(zipfile) { |file|
        while (entry = file.get_next_entry)
          if entry.name==active_record.name
            CSV.parse(file.read,{:headers=>true}) {|row| yield row}
          end
        end
        }
      }
    }
    puts "   -> %.4fs" % time.real
  end

end
