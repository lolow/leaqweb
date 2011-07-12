class ResultSet < ActiveRecord::Base

  validates_uniqueness_of :name

  before_destroy :clear

  EXT = %w{txt mod dat csv log gms inc}
  SCRIPT = {"pivot_table" => 'pivot_table.R.erb',
            "line_graph"  => 'line_graph.R.erb',
            "area_graph"  => 'area_graph.R.erb'}

  def self.auto_new
    name = "result_set_00"
    (1..999).each do |i|
      name.succ!
      break unless ResultSet.find_name(name)
    end
    ResultSet.create!(:name=>name)
  end

  def store_solver(solver)
    FileUtils.mkdir_p(path) unless File.exists?(path)
    path_content = Dir[File.join(path,"file.*")]
    path_content.each{|f| File.delete(f) if File.exists?(f)}
    EXT.each { |x| FileUtils.cp(solver.file(x), file(x)) if File.exist?(solver.file(x)) }
  end

  def perform_query(query)
    #clean
    File.delete(file("res")) if File.exists?(file("res"))

    template = File.read(File.join(Rails.root, 'lib', SCRIPT[query[:display]]))
    @result_set = self
    @query = query

    f = Tempfile.new("R#{self.id}")
    f2 = Tempfile.new("S#{self.id}")
    text = ERB.new(template).result(binding)
    puts text
    f.write(text)
    f.flush
    `R CMD BATCH --vanilla --quiet #{f.path} #{f2.path}`
    f.close
    f2.close

    file("res")
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
