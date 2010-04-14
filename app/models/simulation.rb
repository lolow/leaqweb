class Simulation < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  before_destroy :clear

  EXT = %w{mod dat log out csv}
  ATTRIBUTES = %w{VAR_OBJINV VAR_OBJFIX VAR_OBJVAR VAR_OBJSAL CAPACITY ACTIVITY VAR_IMP VAR_EXP VAR_COM VAR_ICAP}

  def self.auto_new
    prefix = SIM
    name = prefix
    (1..999).each do |i|
      name = prefix + i.to_s
      break unless Simulation.find_name(name)
    end
    Simulation.create!(:name=>name)
  end

  def store_results(solver)
    solver.prepare_results
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

  def results_path
    File.join(RAILS_ROOT,'public','files','sim',self.id.to_s)
  end

  def file(ext)
    File.join(results_path,"sim.#{ext}")
  end

end