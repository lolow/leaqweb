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
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'tenjin'
require 'yaml'
require 'solver'
require 'csv'
require 'etem'
require "fileutils"

class EtemSolver
  include Etem

  # Create a new environment
  def initialize(opts={},token=nil,pid=0)
    @token = token || (1..8).collect{(i=Kernel.rand(62);i+=((i<10)?48:((i<36)?55:61))).chr}.join
    @pid = pid
    @opts = opts.reverse_merge(DEF_OPTS)
  end
                                                                    
  # Solve the model and return pid
  def solve

    exts = case @opts[:language]
      when "GMPL" then ["mod","dat"]
      when "GAMS" then ["gms","inc"]
    end

    exts.each{|ext|copy_template(ext)}

    context = create_context
    context[:f_inc] = file("inc")
    context[:f_csv] = file("csv")
    context[:f_status] = file("status")

    exts.each do |ext|
      puts "Rendering #{ext}" if debug
      File.open(file(ext),"w"){|f|f.puts(engine.render(template(ext),context))}
      puts "- finished" if debug
    end

    puts "Write Glossary" if debug
    File.open(file("txt"), "w") do |f|
     f.puts('ETEM outputs')
     f.puts("Generated on #{Time.now.to_s}")
     f.puts('General parameters')
     f.puts "First year:#{first_year}"
     f.puts "Period duration:#{period_duration}"
     f.puts('Commodity')
     Commodity.activated.each do |c|
       f.puts "#{c.name}\t#{c.description}".force_encoding('UTF-8')
      end
      f.puts('Technology')
      Technology.activated.each do |t|
        f.puts "#{t.name}\t#{t.description}".force_encoding('UTF-8')
      end
    end

    puts "Run command" if debug
    run(command)

  end

  def reset
    kill
    clean
  end

  def log
    File.open(file("log")).read if File.exists?(file("log"))
  end

  def solved?
    case @opts[:language]
    when "GMPL"
      log.index("End:") if File.exists?(file("log"))
    when "GAMS"
      File.exists?(file("status"))
    end
  end

  def optimal?
    case @opts[:language]
    when "GMPL"
      log.index("OPTIMAL SOLUTION FOUND") if File.exists?(file("log"))
    when "GAMS"
      File.read(file("status")).to_i == 1 if File.exists?(file("status"))
    end
  end
  
  def time_used
    return unless solved?
    t1 = Time.parse(log.lines.grep(/Start:/).first)
    t2 = Time.parse(log.lines.grep(/End:/).first)
    t2 - t1
  end

  def has_files?
    File.exists?(file("log"))
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
    %w{gms inc mod dat out log csv status lst txt}.each{|ext|File.delete(file(ext)) if File.exist?(file(ext))}
  end
  
  # Extracts the context data for the generation
  def create_context
    c = Hash.new([])

    ActiveRecord::Base.transaction do

      puts "Sets generation" if debug
      technologies = Technology.activated
      commodities  = Commodity.activated
      markets = Market.activated
      commodity_sets = CommoditySet.activated
      c[:s_s]    = TIME_SLICES
      c[:s_p]    = id_list_name(technologies.all)
      c[:s_m]    = id_list_name(markets.all)
      c[:s_c]    = id_list_name(commodities.all)
      c[:s_enc]  = id_list_name(commodities.energy_carriers)
      c[:s_imp]  = id_list_name(commodities.imports)
      c[:s_exp]  = id_list_name(commodities.exports)
      c[:s_dem]  = id_list_name(commodities.demands)
      c[:s_agg]  = id_list_name(commodity_sets.all)

      c[:s_in_flow]  = Hash.new
      c[:s_out_flow] = Hash.new
      technologies.each do |t|
        c[:s_in_flow][t.name]  = id_list_flow(t.in_flows)
        c[:s_out_flow][t.name] = id_list_flow(t.out_flows)
      end

      technology_ids = technologies.all.map(&:id)
      flows = Flow.joins(:technology).where(:technology_id=>technology_ids)
      c[:s_flow] = id_list_flow(flows.all)

      c[:s_c_items] = Hash.new
      flows.all.each{|f| c[:s_c_items]["f_#{f.id}"] = id_list_name(f.commodities)&c[:s_c]}

      c[:s_c_agg] = Hash.new
      commodity_sets.all.each{|agg| c[:s_c_agg][agg.name] = id_list_name(agg.commodities)&c[:s_c]}

      c[:s_p_market] = Hash.new
      markets.all.each{|m| c[:s_p_market][m.name] = id_list_name(m.technologies)&c[:s_p]}

      puts "Parameters generation" if debug

      commodity_ids  = commodities.all.map(&:id)
      commodity_set_ids  = commodity_sets.all.map(&:id)
      flow_ids       = flows.all.map(&:id)
      market_ids     = markets.all.map(&:id)

      #Select scenarios
      scenarios = ["BASE"] + @opts[:scenarios].scan(/[a-zA-Z\d]+/)
      scenario_ids = scenarios.collect{|s|Scenario.find_by_name(s)}.compact
      scenario_ids.uniq!

      signature.each_key do |param|
        puts "- #{param}" if debug
        c["p_#{param}_d".to_sym] = default_value_for(param)
        if signature[param]
          c["p_#{param}".to_sym] = []
          scenario_ids.each do |scenario_id|
            pv = ParameterValue.of(param.to_s).where(:scenario_id=>scenario_id)
            pv = pv.where(:technology_id=> technology_ids) if signature[param].include?("technology")
            pv = pv.where(:commodity_id=> commodity_ids)   if signature[param].include?("commodity")
            pv = pv.where(:commodity_set_id=> commodity_set_ids)   if signature[param].include?("commodity_set")
            pv = pv.where(:in_flow_id => flow_ids)         if signature[param].include?("in_flow")
            pv = pv.where(:out_flow_id => flow_ids)        if signature[param].include?("out_flow")
            pv = pv.where(:flow_id => flow_ids)            if signature[param].include?("flow")
            pv = pv.where(:market_id => market_ids)        if signature[param].include?("market")
            pv = pv.where(:sub_market_id => market_ids)    if signature[param].include?("sub_market")
            new_values = values_for(param,pv)
            if scenario_id == scenario_ids.first
              c["p_#{param}".to_sym] += new_values
            else
              if new_values.size > 0
                # if new values exist, replace values
                idx = signature[param].length
                c_idx = c["p_#{param}".to_sym].each_slice(idx+1).collect{|x|x[0..-2].join(" ")}
                to_add = []
                new_values.each_slice(idx+1) do |slice|
                  find = c_idx.index(slice[0..-2].join(" "))
                  if find
                    c["p_#{param}".to_sym][find*(idx+1)+idx] = slice[-1]
                  else
                    to_add += slice
                  end
                end
                c["p_#{param}".to_sym] += to_add
              end
            end
          end
        end
      end
      c[:p_nb_periods_d]    = nb_periods
      c[:p_period_length_d] = period_duration
      c[:p_first_year_d]    = first_year

      c[:p_market] = markets.map{|m| m.technologies.activated.map{|t| "#{t.name} #{m.name} 1"}}.join(" ")

      # frac_dem - fill the parameter if no value are available
      fill_dmd = c[:s_dem] - c[:p_frac_dem].select{|x| x =~ /\w+/ }
      fill_dmd.each do |d|
        TIME_SLICES.each do |ts|
          c[:p_frac_dem] << ts << d << fraction[ts]
        end
      end

    end

    c
  end                    

  # Returns the default value of the parameter
  def default_value_for(parameter)
    dv = Parameter.find_by_name(parameter.to_s).default_value
    case parameter
      when "avail" then period(dv)
      when "life"  then dv.to_i/period_duration
      else dv
    end
  end

  # Returns an array of the parameter values
  # Values are projected over periods if necessary.
  def values_for(parameter,parameter_values)
    pv = parameter_values
    return [] unless pv.count > 0
    # If Values are time-dependent
    if signature[parameter].include?("period")
      values = Hash.new
      # Value are gathered by indexes other than period
      case parameter
      when "demand"
        Commodity.demands.activated.each{|dem|
          key = "_T " + dem.name
          values[key] = Hash.new
          dem.demand_values(first_year).each{|dv|
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
      # Values are projected/disaggregated
      str = []
      values.each{ |key,k_values|
        projection(k_values,time_proj[parameter]).each{|period,value|
          if key.index("_AN")
            TIME_SLICES.each { |ts|
              str.concat(key.sub("_AN",ts).sub(/_T/,period.to_s).split)
              if inherit_ts[parameter]==:same
                str << value
              elsif inherit_ts[parameter]==:fraction
                str << value * fraction[ts]
              end
            }
          else
            str.concat(key.sub(/_T/,period.to_s).split)
            str << value
          end
        }
      }
      str
    else
      pv.collect{ |v|
        key = parameter_value_indexes(parameter,v).join(" ")
        value =  case parameter
                 when "flow_act" then "f_#{v.flow.id}"
                 when "avail"    then "#{period(v.value)}"
                 when "life"     then "#{v.value/period_duration}"
                 else "#{v.value}"
                 end
        str = []
        if key.index("_AN")
          TIME_SLICES.each { |ts|
            str.concat(key.sub("_AN",ts).split)
            if inherit_ts[parameter]==:same
              str << value
            elsif inherit_ts[parameter]==:fraction
              str << value.to_f * fraction[ts]
            end
          }
        else
          str.concat(key.split)
          str << value
        end
        str
      }.flatten
    end
  end

  # Return a string which is a list of prefixed ids
  def id_list_name(items)
    items.map(&:name)
  end

  # Return a string which is a list of prefixed ids
  def id_list_flow(items)
    items.collect{|f|"f_#{f.id}"}
  end

  # Returns an array of string that contains the parameter value indexes
  # - parameter: parameter as a symbol
  # - row: the ParameterValue instance
  def parameter_value_indexes(parameter,row)
    signature[parameter].collect { |idx|
      case idx
      when "period"        then "_T"
      when "time_slice"    then (row.time_slice=="AN" ? "_AN" : row.time_slice)
      when "commodity"     then row.commodity.name
      when "commodity_set" then row.commodity_set.name
      when "technology"    then row.technology.name
      when "flow"          then "f_#{row.flow.id}"
      when "in_flow"       then "f_#{row.in_flow.id}"
      when "out_flow"      then "f_#{row.out_flow.id}"
      when "market"        then row.market.name
      when "sub_market"    then row.sub_market.name
      end
    }
  end

  def engine
    @engine ||= Tenjin::Engine.new
  end

  def copy_template(ext)
    puts "copy template #{ext}" if debug
    origin = File.join(@opts[:model_path],"etem.#{ext}.template")
    destination = template(ext)
    if !File.exist?(destination) || (File.ctime(origin)-File.ctime(destination))>0
      FileUtils.cp(origin,destination)
    end
  end

  def template(ext)
    File.join(@opts[:temp_path],"etem.#{ext}.template")
  end

  def file(ext)
    File.join(@opts[:temp_path],"temp-#{@token}.#{ext}")
  end

  def run(cmd)
    puts cmd if debug
    if @opts[:wait_solver]
      @pid = nil
      system(cmd)
    else
      @pid = fork do
        exec(*cmd)
        exit! 1
      end
    end
  end

  def command
    "echo Start: `date` " +
    (@opts[:log_file] ? "> #{file("log")} " : "") +
    case @opts[:language]
    when "GMPL"
      "&& nice glpsol -m #{file("mod")} -d #{file("dat")} -y #{file("csv")} " +
      (@opts[:log_file] ? ">> #{file("log")} " : "")
    when "GAMS"
      "&& gams #{file("gms")} -o #{file("lst")} lo=3 ll=0 " +
      (@opts[:log_file] ? ">> #{file("log")} " : "")
    end +
    "&& echo End: `date` " +
    (@opts[:log_file] ? ">> #{file("log")} " : "")
  end

  def first_year
    @opts[:first_year]
  end

  def last_year
    first_year+period_duration*nb_periods-1
  end

  def nb_periods
    @opts[:nb_periods]
  end

  def period_duration
    @opts[:period_duration]
  end

  def period(year)
    [[((year - first_year) / period_duration + 1).to_i,1].max,nb_periods].min
  end

  def periods
    @etem_periods ||=  nb_periods.times.collect{|x|x*period_duration+first_year}
  end

  def debug
    @opts[:debug]
  end

end