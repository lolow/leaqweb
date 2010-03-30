module Toolbox

  def say(message, subitem=false)
    puts "#{subitem ? "   ->" : "--"} #{message}"
  end

  def tictoc(message,debug=true)
      return unless debug
      require 'benchmark'
      say(message)
      time = Benchmark.measure { yield }
      say "%.4fs" % time.real, :subitem
  end

end