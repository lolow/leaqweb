class Output < ActiveRecord::Base

  validates_presence_of :name
  validates_uniqueness_of :name

  before_destroy :clear

  TMP = "/tmp"
  EXT = %w{mod dat csv out log}

  def self.auto_new
    name = "output_00"
    (1..999).each do |i|
      name.succ!
      break unless Output.find_name(name)
    end
    Output.create!(:name=>name)
  end

  def store_solver(solver)
    solver.prepare_results
    FileUtils.mkdir_p(path) unless File.exists?(path)
    File.delete(file("Renv")) if File.exists?(file("Renv"))
    EXT.each { |x| FileUtils.cp(solver.file(x),file(x)) }
  end

  def compute_cross_tab(table)
    @output = self
    @table = table
    File.delete(file("tab")) if File.exists?(file("tab"))
    template = File.read(File.join(Rails.root,'lib','cross_tab.R.erb'))
    f = Tempfile.new("R#{self.id}")
    f2 = Tempfile.new("S#{self.id}")
    text = ERB.new(template).result(binding)
    puts text
    f.write(text)
    f.flush
    `R CMD BATCH --vanilla --quiet #{f.path} #{f2.path}`
    f.close
    f2.close
  end

  def cross_tab
    File.read(file("tab")) if File.exists?(file("tab"))
  end

  def has_results?
    File.exists?(file("csv"))
  end

  def file(ext)
    File.join(path,"file.#{ext}")
  end

  private

  def path
    File.join(Rails.root,'public','files','out',self.id.to_s)
  end

  def clear
    EXT.each { |x| File.delete(file(x)) if File.exists?(file(x)) }
    File.delete(file("Renv")) if File.exists?(file("Renv"))
    FileUtils.rm_rf(path) if File.exists?(path)
  end

end
