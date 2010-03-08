module Toolbox

  def tic
    Time.now.usec
    @@before = Time.now
  end

  def toc
    "[#{Time.now - @@before} sec(s).]\n"
  end

  def tictoc
    tic
    yield
    toc
  end

end