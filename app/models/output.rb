class Output < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name

  before_destroy :clear

  ATTRIBUTES = %w{VAR_OBJINV VAR_OBJFIX VAR_OBJVAR VAR_OBJSAL CAPACITY ACTIVITY VAR_IMP VAR_EXP VAR_COM VAR_ICAP}
  TMP = "/tmp"

  def self.auto_new
    prefix = "OUT"
    name = prefix
    (1..999).each do |i|
      name = prefix + i.to_s
      break unless Output.find_name(name)
    end
    Output.create!(:name=>name)
  end

  def store_solver(solver)
    solver.prepare_results
    FileUtils.mkdir_p(path) unless File.exists?(path)
    File.delete(temp_renv_file) if File.exists?(temp_renv_file)
    EXT.each { |x| FileUtils.cp(solver.file(x),file(x)) }
  end

  def compute_cross_table(attribute,formula,filter=nil)
    @simulation = self
    @attribute = attribute
    @formula = formula
    @filter = filter
    template = File.read(File.join(RAILS_ROOT,'lib','cross_table.erb'))
    f = Tempfile.new('R'+params[:id])
    f.write(ERB.new(template).run)
    f.flush
    `R CMD BATCH #{f.path} --vanilla --no-readline`
    f.close
  end

  def has_results?
    File.exists?(file("csv"))
  end

  private

  def path
    File.join(RAILS_ROOT,'public','files','out',self.id.to_s)
  end

  def clear
    EXT.each {|x| File.delete(file(x)) if File.exists?(file(x)) }
    FileUtils.rmdir(path)  if File.exists?(path)
  end

  def file(ext)
    File.join(path,"sim.#{ext}")
  end

end