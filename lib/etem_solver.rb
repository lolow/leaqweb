require 'tenjin'
require 'yaml'
require 'benchmark'

require 'etem'

class EtemSolver
  include Etem

  # Create a new environment
  def initialize(token=nil,pid=0,opts={})
    opts = update_etem_options(opts)
    @token = token || (1..8).collect{(i=Kernel.rand(62);i+=((i<10)?48:((i<36)?55:61))).chr}.join
    @pid = pid
  end
                                                                    
  # Solve the model and return pid
  def solve(opts={})
    opts = update_etem_options(opts)
    ["mod","dat"].each{|ext|copy_template(ext)}

    puts "Create context" if opts[:debug]
    context = create_context(opts[:debug])
    context["write_outputs"] = opts[:write_output]
    opts[:ignore_equations].each { |eq| context[eq] = true  }

    %w{mod dat}.each do |ext|
      puts "Generate .#{ext} file" if opts[:debug]
      File.open(file(ext),"w"){|f|f.puts(engine.render(template(ext),context))}
    end

    puts "Run optimization solver" if opts[:debug]
    run(command)
  end

  def reset
    kill
    clean
  end

  def prepare_results
    return unless solved?
    if optimal?
      dict = Hash[*Commodity.all.collect{|x|[x.pid,x.name]}.flatten]
      dict.merge! Hash[*Technology.all.collect{|x|[x.pid,x.name]}.flatten]
      FasterCSV.open(file("csv"), "w") do |csv|
        csv << %w[attribute T S P C value]
        header = true
        FasterCSV.foreach(file("out")) do |row|
          csv << [row[0],row[1],row[2],dict[row[3]],dict[row[4]],row[5]] unless header
          header = false
        end
      end
    end
  end

  def log
    File.open(file("log")).read if File.exists?(file("log"))
  end

  def solved?
    log.index("End:") if File.exists?(file("log"))
  end

  def optimal?
    log.index("OPTIMAL SOLUTION FOUND") if File.exists?(file("log"))
  end
  
  def time_used
    return unless solved?
    t1 = Time.parse(log.grep(/Start:/).first)
    t2 = Time.parse(log.grep(/End:/).first)
    t2 - t1
  end

  def has_files?
    %w{mod dat out log}.inject(true){ |enum,x| enum && File.exists?(file(x)) }
  end

  def kill
    begin
      #glpsol
      pids = `pidof -x glpsoldot`.split(" ").map(&:to_i).sort
      Process.kill("SIGKILL",pids[0]) unless pids.empty?
      #wait the end of the script
      Process.waitpid(@pid, 0) if @pid>0
    rescue
      nil
    end
  end

  def clean
    %w{mod dat out log csv}.each{|ext|File.delete(file(ext)) if File.exist?(file(ext))}
  end
  
  # Extracts the context data for the generation
  def create_context(debug=false)
    c = Hash.new("")

    # sets generation
    technologies = Technology.tagged_with("P")
    commodities  = Commodity.tagged_with("C")
    flows = Flow.joins(:technology).where(:technology_id=>technologies)
    c[:s_s]    = TIME_SLICES.join(" ")
    c[:s_p]    = id_list(technologies.all)
    c[:s_c]    = id_list(commodities.all)
    c[:s_imp]  = id_list(commodities.tagged_with("IMP"))
    c[:s_exp]  = id_list(commodities.tagged_with("EXP"))
    c[:s_dem]  = id_list(commodities.tagged_with("DEM"))
    c[:s_flow] = id_list(flows.all)
    
    c[:s_in_flow]  = Hash.new
    c[:s_out_flow] = Hash.new
    technologies.each do |t|
      c[:s_in_flow][t.pid]  = id_list(t.in_flows)
      c[:s_out_flow][t.pid] = id_list(t.out_flows)
    end
    
    c[:s_c_items] = Hash.new
    flows.all.each{|f| c[:s_c_items][f.pid] = id_list(f.commodities)}
    
    # parameters generation
    signature.each_key do |param|
      c["p_#{param}_d".to_sym] = default_value_for(param)
      if signature[param]
        pv = ParameterValue.of(param.to_s)
        pv = pv.where(:technology_id=> technologies) if signature[param].include?("technology")
        pv = pv.where(:commodity_id=> commodities) if signature[param].include?("commodity")
        pv = pv.where(:in_flow_id => flows) if signature[param].include?("in_flow")
        pv = pv.where(:out_flow_id => flows) if signature[param].include?("out_flow")
        pv = pv.where(:flow_id => flows) if signature[param].include?("flow")
        c["p_#{param}".to_sym]   = values_for(param,pv)
      end
    end
    c["p_nb_periods_d"]    = nb_periods
    c["p_period_length_d"] = period_duration

    # frac_dem - fill the parameter if no value are available
    fill_dmd = c[:s_dem].scan(/\w+/) - c[:p_frac_dem].scan(/\w+/)
    fill_dmd.each do |d|
      TIME_SLICES.each{|ts| c[:p_frac_dem] += " #{ts} #{d} #{fraction[ts]} "}
    end
    c
  end                    

  # Returns the default value of the parameter
  def default_value_for(parameter)
    dv = Parameter.find_by_name(parameter.to_s).default_value
    case parameter
      when "avail" then period(dv)
      when "life"  then dv/period_duration
      else dv
    end
  end

  # Returns a string of the parameter values written in GMPL.
  # Values are projected over periods if necessary.
  def values_for(parameter,parameter_values)
    pv = parameter_values
    # If Values are time-dependent
    if signature[parameter].include?("period")
      values = Hash.new
      # Value are gathered by indexes other than period
      case parameter
      when "demand"
        Commodity.tagged_with("DEM").tagged_with("C").each{|dem|
          key = "T " + Commodity.pid(dem.id)
          values[key] = Hash.new
          dem.demand_values.each{|dv|
            values[key][dv[0]] = dv[1]
          }
        }
      else
        pv.each{ |v|
          key = parameter_value_indexes(parameter,v).join(" ")
          values[key] = Hash.new if not values[key]
          values[key][v.year] = v.value
        }
      end
      # Values are projected/desagregated if necessary
      str = []
      values.each{ |key,k_values|
        p key
        p k_values
        projection(k_values,time_proj[parameter]).each{|period,value|
          if key.index("AN")
            TIME_SLICES.each { |ts|
              str << key.sub("AN",ts).sub(/[T]/,period.to_s)
              if inherit_ts[parameter]==:same
                str << value
              elsif inherit_ts[parameter]==:fraction
                str << value * fraction[ts]
              end
            }
          else
            str << key.sub(/[T]/,period.to_s)
            str << value
          end
        }
      }
      str.join(" ")
    else
      pv.collect{ |v|
        str = parameter_value_indexes(parameter,v)
        str <<  case parameter
                when "flow_act" then Flow.pid(v.flow.id)
                when "avail"    then "#{period(v.value)}"
                when "life"     then "#{v.value/period_duration}"
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
      when "period"        then "T"
      when "time_slice"    then row.time_slice
      when "commodity"     then Commodity.pid(row.commodity_id)
      when "technology"    then Technology.pid(row.technology_id)
      when "flow"          then Flow.pid(row.flow.id)
      when "in_flow"       then Flow.pid(row.in_flow.id)
      when "out_flow"      then Flow.pid(row.out_flow.id)
      end
    }
  end

  def engine
    @engine ||= Tenjin::Engine.new
  end

  def copy_template(ext)
    origin = File.join(model_path,"etem.#{ext}.template")
    destination = template(ext)
    if !File.exist?(destination) || (File.ctime(origin)-File.ctime(destination))>0
      FileUtils.cp(origin,destination)
    end
  end

  def template(ext)
    File.join(temp_path,"etem.#{ext}.template")
  end

  def file(ext)
    File.join(temp_path,"temp-#{@token}.#{ext}")
  end
  
  def say(message,debug)
    puts "-- #{message}" if debug
    time = Benchmark.measure {
      yield
    }
    puts "   -> %.4fs" % time.real if debug
  end

  def run(*cmd)
    puts cmd
    @pid = fork do
      exec(*cmd)
      exit! 127
    end
  end

  def command
    "echo Start: `date` > #{file("log")} " +
    "&& glpsoldot -m #{file("mod")} -d #{file("dat")} -y #{file("out")} >> #{file("log")} " +
    "&& echo End: `date` >> #{file("log")} "
  end
    
end