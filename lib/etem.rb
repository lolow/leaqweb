# Module ETEM
# common methods and constant

module Etem

  AGGREGATES = %w{SUM MEAN}
  VARIABLES  = %w{VAR_OBJINV VAR_OBJFIX VAR_OBJVAR VAR_OBJSAL} +
               %w{CAPACITY ACTIVITY VAR_IMP VAR_EXP VAR_COM VAR_ICAP DEMAND} +
               %w{C_PRICE VAR_AGG}
  PARAM_COMMODITIES = %w{demand frac_dem} +
                      %w{network_efficiency peak_reserve} +
                      %w{cost_imp cost_exp imp_bnd_lo imp_bnd_fx imp_bnd_up} +
                      %w{exp_bnd_lo exp_bnd_fx exp_bnd_up } +
                      %w{com_net_bnd_up_t com_net_bnd_up_ts}
  PARAM_TECHNOLOGIES = %w{input output eff_flo flow_act} +
                       %w{flo_bnd_lo flo_bnd_fx flo_bnd_up} +
                       %w{flo_share_lo flo_share_fx flo_share_up} +
                       %w{peak_prod cost_delivery act_flo} + %w{fixed_cap} +
                       %w{life avail cap_act  avail_factor} +
                       %w{cost_vom cost_fom cost_icap} +
                       %w{act_bnd_lo act_bnd_fx act_bnd_up} +
                       %w{cap_bnd_lo cap_bnd_fx cap_bnd_up} +
                       %w{icap_bnd_lo icap_bnd_fx icap_bnd_up market}
  INDEX = { "T" => "Time period",
            "S" => "Time slice",
            "P" => "Processes",
            "C" => "Commodities",
            "M" => "Markets" }.freeze
  VALID_NAME = "Please use only letters, numbers or symbol '-' in name"


  DEF_OPTS = {:temp_path => "/tmp",
              :model_path => File.join(Rails.root,'lib','etem'),
              :wait_solver => false,
              :language => "GAMS", # or "GMPL"
              :debug => true,
              :log_file => true,
              :ignore_equations => [],
              :write_output => true,
              :period_duration => 1,
              :nb_periods => 26,
              :first_year => 2005
             }.freeze

  TIME_SLICES = %w{WD WN SD SN ID IN}

  def signature
    @signature ||= ParameterValue::SIGNATURE
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

  def next_available_name(klass,name)
    counter = 0
    available_name=name
    while klass.find_by_name(available_name)
      available_name=name + "-#{counter+=1}"
    end
    available_name
  end

end
