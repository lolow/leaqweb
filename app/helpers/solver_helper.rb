module SolverHelper
  def log_with_link(log)
    return unless log
    log.gsub!(/t\d+/){|s| raw link_to(s, :controller=>"technologies",:action=>"edit",:id=>s[1,s.size-1]) }
    log.gsub!(/c\d+/){|s| raw link_to(s, :controller=>"commodities",:action=>"edit",:id=>s[1,s.size-1]) }
    log.gsub!(/f\d+/){|s| raw link_to(s, :controller=>"technologies",:action=>"edit",:id=>Flow.find(s[1,s.size-1]).technology.id) }
    log
  end
end
