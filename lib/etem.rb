# Module ETEM
# Collection of methods useful for EtemSolver

module Etem

  DEF_OPTS = {:temp_path => "/tmp",
              :model_path => File.join(RAILS_ROOT,'lib','etem'),
              :debug => false,
              :ignore_equations => [],
              :write_output => true,
              :period_duration => 5,
              :nb_periods => 9,
              :first_year => 2005
             }.freeze

  TIME_SLICES = %w{WD WN SD SN ID IN}

  def update_etem_options(opts={})
    @opts = opts.reverse_merge(DEF_OPTS)
  end

  def signature
    @signature ||= YAML.load_file(File.join(@opts[:model_path],'param_sign.yml'))
  end

  def time_proj
    @time_proj ||= YAML.load_file(File.join(@opts[:model_path],'param_proj_period.yml'))
  end

  def first_year
    @etem_first_year ||=  Parameter.find_by_name('base_year').default_value.to_i
  end

  def last_year
    first_year+period_duration*nb_periods-1
  end

  def nb_periods
    @etem_nb_periods ||=  Parameter.find_by_name('nb_periods').default_value.to_i
  end

  def period_duration
    @etem_period_duration ||=  Parameter.find_by_name('period_length').default_value.to_i
  end
  
  def period(year)
    [[((year - first_year) / period_duration + 1).to_i,1].max,nb_periods].min
  end

  def periods
    @etem_periods ||= (0..nb_periods-1).collect{|x|x*period_duration+first_year}
  end

  def model_path
    @opts[:model_path]
  end

  def temp_path
    @opts[:temp_path]
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
    elasticity = 1 unless elasticity
    driver_hash.collect{|year,value| [year,base_year_value.to_f*value.to_f**elasticity]}
  end

  def interpolate(x1,x2,y1,y2,x)
    (x.to_f-x1) / (x2-x1) * (y2-y1) + y1
  end

end
