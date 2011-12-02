#--
# Copyright (c) 2009-2011, Public Research Center Henri Tudor
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
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Etem

  AGGREGATES = %w{SUM MEAN}
  VARIABLES  = %w{VAR_OBJINV VAR_OBJFIX VAR_OBJVAR VAR_OBJSAL} +
               %w{CAPACITY ACTIVITY VAR_IMP VAR_EXP VAR_COM VAR_ICAP DEMAND} +
               %w{C_PRICE AGGREGATE COST_IMP}
  INDEX = { "T" => "Time period",
            "S" => "Time slice",
            "P" => "Processes",
            "C" => "Commodities"}.freeze
  VALID_NAME_MSG = "Please use only letters or numbers in name"


  DEF_OPTS = {:temp_path => Dir.tmpdir,
              :model_path => File.join(Rails.root,'lib','etem'),
              :wait_solver => false,
              :language => "GAMS", # or "GMPL"
              :debug => true,
              :log_file => true,
              :write_output => true,
              :period_duration => 1,
              :nb_periods => 26,
              :first_year => 2005,
              :scenarios => "BASE"
             }.freeze

  TIME_SLICES = %w{WD WN SD SN ID IN}

  def signature
    @opts = DEF_OPTS unless @opts
    @signature ||= YAML.load_file(File.join(@opts[:model_path],'param_sign.yml'))
  end

  def time_proj
    @time_proj ||= YAML.load_file(File.join(@opts[:model_path],'param_proj_period.yml'))
  end

  def fraction
    unless @fraction
      @fraction = {}
      Parameter.find_by_name('fraction').parameter_values.each do |row|
        @fraction[row.time_slice] = row.value
      end
    end
    @fraction
  end

  def inherit_ts
    @inherit_ts ||= YAML.load_file(File.join(@opts[:model_path],'param_inherit_ts.yml'))
  end

  # projection of the couples (year,value) in the time periods of ETEM (1..nb_periods)
  def projection(hash,type=nil)
    proj = Hash.new
    # Si l'année `0` est défini, on répète la valeur
    if hash[0]
      periods.each{|year|proj[period(year)]=hash[0]}
    else
      # Projection des valeurs toute les années
      val = hash[hash.keys.min]
      v = (first_year..last_year).collect{|y|
        if hash[y]
          val = hash[y]
        else
          val
        end
      }
      # Calcul pour les seules périodes renseignées
      p_k = hash.keys.collect{|x|period(x)}.uniq.sort
      p_k.each{|p|
        proj[p] = v[(p-1)*period_duration]
        #proj[p] = v[(p-1)*period_duration,period_duration].sum / period_duration
      }
      # Interpolation
      if type == "interpolation" || type == "extrapolation"
        (p_k.first..p_k.last).inject(-1) { |cur,p|
          if proj[p]
            cur += 1 # slide cursor position
          else
            proj[p] = interpolate(p_k[cur],p_k[cur+1],proj[p_k[cur]],proj[p_k[cur+1]],p)
            cur      # return cursor position
          end
        }
      end
      # Extrapolation
      if type == "extrapolation"
        (1..p_k.first-1).each{|x|proj[x]=proj[p_k.first]} unless p_k.first == 1
        (p_k.last+1..nb_periods).each{|x|proj[x]=proj[p_k.last]} unless p_k.last == nb_periods
      end
    end
    proj
  end

  # project useful demand
  def demand_projection(driver_hash,base_year_value,elasticity)
    elasticity = Hash.new(1) unless elasticity
    elasticity = Hash.new(elasticity) unless elasticity.is_a?(Hash)
    driver_hash.collect{|year,value| [year.to_i,base_year_value.to_f*value.to_f**elasticity[year.to_i].to_f]}
  end

  def interpolate(x1,x2,y1,y2,x)
    (x.to_f-x1) / (x2-x1) * (y2-y1) + y1
  end

  def next_available_name(klass,name)
    counter = 0
    available_name=name
    while klass.find_by_name(available_name)
      available_name=name + "-#{counter+=1}"
    end
    available_name
  end

end
