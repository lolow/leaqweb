class Solver < ActiveRecord::Base

  belongs_to :user

  before_destroy :clean

  # State Machine
  include Workflow
  workflow do
    state :new do
      event :solve, :transitions_to => :solving
    end

    state :solving do
      event :complete, :transitions_to => :solved
    end

    state :solved
  end

  def update_status
    if solving? && instance_solver.solved?
      complete!
    end
  end
  
  def solve
    halt! unless new?
    self.pid = instance_solver.solve
    self.save
  end

  def prepare_results
    instance_solver.prepare_results
  end

  def optimal?
    solved? && instance_solver.optimal?
  end

  def log
    instance_solver.log.sub("ENDSOLVER\n","").sub(file("mod"),"mod").sub(file("dat"),"dat") || ""
  end

  def file(ext)
    instance_solver.file(ext)
  end
  
  private
  
  def clean
    instance_solver.kill self.pid unless new?
    instance_solver.clean_files
  end

  def instance_solver
    GeoecuSolver.new(:token=>self.id.to_s)
  end

end
