class Simulation < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  before_destroy :clear

  EXT = %w{mod dat log out csv}

  def store_results(solver)
    return unless solver.optimal?
    FileUtils.mkdir_p(results_path) unless File.exists?(results_path)
    EXT.each { |x| FileUtils.cp(solver.file(x),file(x)) }
  end

  def has_results?
    EXT.inject(true){ |enum,x| enum && File.exists?(file(x)) }
  end

  def clear
    EXT.each {|x| File.delete(file(x)) if File.exists?(file(x)) }
    FileUtils.rmdir(results_path)  if File.exists?(results_path)
  end

  private

  def results_path
    File.join(RAILS_ROOT,'public','files','sim',self.id.to_s)
  end

  def file(ext)
    File.join(results_path,"sim.#{ext}")
  end

end