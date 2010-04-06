class Simulation < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  def store_results(solver)
    return unless solver.finished? && solver.optimal?
    ext = %w{mod dat log out csv}
    path = File.join(RAILS_ROOT,'public','files','sim',self.id.to_s)
    FileUtils.mkdir_p(path)
    ext.each { |x| FileUtils.cp(solver.file(x),File.join(path,"sim.#{x}"))  }
  end

end
