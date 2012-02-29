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

class ResultSet < ActiveRecord::Base

  validates_uniqueness_of :name

  before_destroy :clear

  scope :matching_text, lambda {|text| where(['name LIKE ?'] + ["%#{text}%"]) }
  scope :matching_tag #empty

  def store_solver(solver)
    FileUtils.mkdir_p(path) unless File.exists?(path)
    path_content = Dir[File.join(path,"file.*")]
    path_content.each{|f| File.delete(f) if File.exists?(f)}
    s = solver.etem_solver
    s.extensions.each do |x|
      FileUtils.cp(s.file(x), file(x)) if File.exist?(s.file(x))
    end
  end

  def has_results?
    File.exists?(file("csv"))
  end

  def file(ext)
    File.join(path, "file.#{ext}")
  end

  def path
    File.join(ResultSet::parent_path, self.id.to_s)
  end

  def self.delete_result_set_files
    include FileUtils
    path_content = Dir[File.join(parent_path,"*")]
    path_content.each{|r| FileUtils.rm_r(r) if File.exists?(r) && File.directory?(r)}
  end

  private

  def self.parent_path
    File.join(Rails.root, 'public', 'files', 'out')
  end

  def clear
    EXT.each { |x| File.delete(file(x)) if File.exists?(file(x)) }
    File.delete(file("Renv")) if File.exists?(file("Renv"))
    FileUtils.rm_rf(path) if File.exists?(path)
  end

end
