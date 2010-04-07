class Simulation < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  before_destroy :delete_results

  EXT = %w{mod dat log out csv}

  def store_results(solver)
    return unless solver.finished? && solver.optimal?
    FileUtils.mkdir_p(results_path)
    EXT.each do |x|
      FileUtils.cp(solver.file(x),File.join(results_path,"sim.#{x}"))
    end
  end

  private

  def results_path
    File.join(RAILS_ROOT,'public','files','sim',self.id.to_s)
  end

  def delete_results
    EXT.each do |x|
      f = File.join(results_path,"sim.#{x}")
      File.delete(f) if File.exists?(f)
    end
    FileUtils.rmdir(results_path)
  end

end
