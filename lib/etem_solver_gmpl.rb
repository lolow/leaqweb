#--
# Copyright (c) 2009-2012, Public Research Center Henri Tudor
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
require 'etem_solver'

class EtemSolverGmpl < EtemSolver
  GLPSOL="/usr/local/bin/glpsol"

  #Return the file extensions of the template
  def template_extensions
    %w(mod dat)
  end

  def optimal?
    log.index("OPTIMAL SOLUTION FOUND") if File.exists?(file("log"))
  end

  def log
    File.exists?(file("log")) ? File.open(file("log")).read : ""
  end

  def command_line
    "echo Start: `date` | tee #{file("log")} " +
    "&& nice #{GLPSOL} -m #{file("mod")} -d #{file("dat")} -y #{file("csv")}  | tee -a #{file("log")} " +
    "&& echo End: `date`| tee -a #{file("log")} "
  end

end