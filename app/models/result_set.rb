# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class ResultSet < ActiveRecord::Base

  validates_uniqueness_of :name

  before_destroy :clear

  EXT = %w{txt mod dat csv log gms inc}

  scope :matching_text, lambda {|text| where(['name LIKE ?'] + ["%#{text}%"]) }
  scope :matching_tag #empty

  def store_solver(solver)
    FileUtils.mkdir_p(path) unless File.exists?(path)
    path_content = Dir[File.join(path,"file.*")]
    path_content.each{|f| File.delete(f) if File.exists?(f)}
    EXT.each { |x| FileUtils.cp(solver.file(x), file(x)) if File.exist?(solver.file(x)) }
  end

  def has_results?
    File.exists?(file("csv"))
  end

  def file(ext)
    File.join(path, "file.#{ext}")
  end

  def path
    File.join(Rails.root, 'public', 'files', 'out', self.id.to_s)
  end

  private

  def clear
    EXT.each { |x| File.delete(file(x)) if File.exists?(file(x)) }
    File.delete(file("Renv")) if File.exists?(file("Renv"))
    FileUtils.rm_rf(path) if File.exists?(path)
  end

end
