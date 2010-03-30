require 'tenjin'
require 'yaml'
require 'benchmark'

class LeaqSolver 
  
    DEF_OPTS = {:temp_path => "/tmp",
	              :model_path => File.join(RAILS_ROOT,'lib','geoecu'),
                :period_duration => 5,                  
                :nb_periods => 9,
                :first_year => 2005}.freeze
    
  # Create a new environment to solve borat.
  def initialize(opts={})
    @opts = opts.reverse_merge(DEF_OPTS)
    ["mod","dat"].each{|ext|copy_template(ext)}
  end
                                                                    
  # Solve the borat model.
  def solve(debug=false)
    context={}
    say("Create context",debug) do
      context = create_context
    end
    %w{mod dat}.each do |ext|
      say("Generate .#{ext} file",debug) do
        File.open(file(ext),"w"){|f|f.puts(engine.render(template(ext),context))}
      end
    end
    say("Run optimization solver",debug) do
      command("glpsol -m #{file("mod")} -d #{file("dat")} -y #{file("out")}")
    end
    say("Delete temporary files",debug) do
      #%w{mod dat out log}.each{|ext|File.delete(file(ext)) if File.exist?(file(ext))}
    end
  end

  def signature
    @signature ||= YAML.load_file(File.join(@opts[:model_path],'param_sign.yml'))
  end
    
  def time_proj
    @time_proj ||= YAML.load_file(File.join(@opts[:model_path],'param_proj_period.yml'))
  end
  
  def first_year
    @opts[:first_year]
  end
  
  def last_year
    @opts[:first_year]+@opts[:period_duration]*@opts[:nb_periods]-1
  end
  
  def nb_periods
    @opts[:nb_periods]
  end
  
  def period_duration
    @opts[:period_duration]
  end
    
#  private
    
  # Extracts the context data for the generation
  def create_context(debug=nil)
    c = Hash.new("")
    
    # sets generation
    time_slices = %w{WD WN SD SN ID IN}
    c[:s_s]    = time_slices.join(" ")
    c[:s_l]    = id_list(Location.all)
    c[:s_p]    = id_list(Technology.all)
    c[:s_c]    = id_list(Commodity.all)
    c[:s_imp]  = id_list(Commodity.tagged_with("IMP")) if Tag.find_by_name("IMP")
    c[:s_exp]  = id_list(Commodity.tagged_with("EXP")) if Tag.find_by_name("EXP")
    c[:s_dem]  = id_list(Commodity.tagged_with("DEM")) if Tag.find_by_name("DEM")
    c[:s_flow] = id_list(Flow.all)
    
    c[:s_p_map] = Hash.new
    Location.find(:all).each do |l|
      c[:s_p_map][l.pid] = id_list(l.technologies)
    end
    
    c[:s_in_flow]  = Hash.new
    c[:s_out_flow] = Hash.new
    Technology.all.each do |t|
      c[:s_in_flow][t.pid]  = id_list(t.in_flows)
      c[:s_out_flow][t.pid] = id_list(t.out_flows)
    end
    
    c[:s_c_items] = Hash.new
    Flow.all.each{|f| c[:s_c_items][f.pid] = id_list(f.commodities)}
    
    # parameters generation
    signature.each_key do |param|
      c["p_#{param}_d".to_sym] = default_value_for(param)
      c["p_#{param}".to_sym]   = values_for(param)
    end
    c["p_nb_periods_d"]    = nb_periods
    c["p_period_length_d"] = period_duration

    # frac_dem - fill the parameter if no value are available
    f = Hash.new
    Parameter.find_by_name('fraction').parameter_values.each do |row|
      f[row.time_slice] = row.value
    end
    fill_dmd = c['s_dem'].scan(/\w+/) - c['p_frac_dem'].scan(/\w+/)
    fill_dmd.each do |d|
      time_slices.each{|ts| c['p_frac_dem'] += " #{ts} #{d} #{f[ts]} "}
    end
    c
  end                    

  def period(year)
    [[((year - first_year) / period_duration + 1).to_i,1].max,nb_periods].min
  end

  def periods
    @periods ||= (0..nb_periods-1).collect{|x|x*period_duration+first_year}
  end

  # Project (year,value) in the time periods of ETEM (1..nb_periods)
  def projection(hash,type=nil)
    proj = Hash.new
    # Si l'année `0` est défini, on répète la valeur
    if hash[0]
      periods.each{|year|proj[period(year)]=hash[0]}
    else
      # Projection des valeurs en chaque année
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
        proj[p] = v[(p-1)*period_duration,period_duration].sum / period_duration
      }
      # Interpolation
      if type == :interpolation || type == :extrapolation
        (p_k.first..p_k.last).inject(-1) { |i,p|
          if proj[p]
            i += 1
          else
            proj[p] = interpolate(p_k[i],p_k[i+1],proj[p_k[i]],proj[p_k[i+1]],p)
          end
        }
      end
      # Extrapolation
      if type == :extrapolation
        (1..p_k.first-1).each{|x|proj[x]=proj[p_k.first]} unless p_k.first == 1
        (p_k.last+1..nb_periods).each{|x|proj[x]=proj[p_k.last]} unless p_k.last ==  9
      end
    end
    proj
  end

  # Returns the default value of the parameter
  def default_value_for(parameter)
    dv = Parameter.find_by_name(parameter.to_s).default_value
    case parameter
      when :avail then period(dv)
      when :life  then dv/period_duration
      else dv
    end
  end

  # Returns a string of the parameter values written in GMPL.
  # Values are projected over periods if necessary.
  def values_for(parameter)
    return unless signature[parameter]
    pv  = Parameter.find_by_name(parameter.to_s).parameter_values
    # If Values are time-dependent
    if signature[parameter].include?(:period)
      values = Hash.new
      # Value are gathered by indexes other than period
      pv.each{ |v|
        key = parameter_value_indexes(parameter,v).join(" ")
        values[key] = Hash.new if not values[key]
        values[key][v.year] = v.value
      }
      # Values are projected if necessary
      str = []
      values.each{ |key,k_values|
        projection(k_values,projection_type[parameter]).each{|period,value|
          str << key.sub(/[T]/,"#{period}")
          str << value
        }
      }
      str.join(" ")
    else
      pv.collect{ |v|
        str = parameter_value_indexes(parameter,v)
        str <<  case parameter
                when :flow_act then Flow.pid(v.flow.id)
                when :avail    then "#{period(v.value)}"
                when :life     then "#{v.value/period_duration}"
                else "#{v.value}"
                end
        str
      }.join(" ")
    end
  end

  # Return a string which is a list of prefixed ids
  def id_list(items)
    items.collect{|x|"#{x.pid}"}.join(" ")
  end

  # Returns an array of string that contains the parameter value indexes
  # - parameter: parameter as a symbol
  # - row: the ParameterValue instance
  def parameter_value_indexes(parameter,row)
    signature[parameter].collect { |idx|
      case idx
      when :period        then "T"
      when :time_slice    then row.time_slice
      when :commodity     then Commodity.pid(row.commodity_id)
      when :technology    then Technology.pid(row.technology_id)
      when :location      then Location.pid(row.location_id)
      when :flow          then Flow.pid(row.flow.id)
      when :in_flow then Flow.pid(row.in_flow.id)
      when :out_flow then Flow.pid(row.out_flow.id)
      end
    }
  end

  def engine
    @engine ||= Tenjin::Engine.new
  end

  def copy_template(ext)
    origin = File.join(@opts[:model_path],"geoecu.#{ext}.template")
    destination = template(ext)
    if !File.exist?(destination) || (File.ctime(origin)-File.ctime(destination))>0
      FileUtils.cp(origin,destination)
    end
  end

  def template(ext)
    File.join(@opts[:temp_path],"geoecu.#{ext}.template")
  end

  def token
    @token ||= (1..8).collect{(i=Kernel.rand(62);i+=((i<10)?48:((i<36)?55:61))).chr}.join
  end

  def file(ext)
    File.join(@opts[:temp_path],"temp-" + token + ".#{ext}")
  end

  def interpolate(x1,x2,y1,y2,x)
    (x.to_f-x1) / (x2-x1) * (y2-y1) + y1
  end

  def command(cmd)
    unless system cmd
     $?
    end
  end
  
  def say(message,debug)
    puts "-- #{message}"
    time = Benchmark.measure {
      yield
    }
    puts "   -> %.4fs" % time.real
  end
    
end
