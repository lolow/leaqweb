#collections of functions to help the feeding of the database
require 'yaml'

module EtemTools

  def generate_new_technology(yml_file,end_year=2030)
    YAML.load_file(yml_file).each do |row|
      tech0 = Technology.find_by_name(row["technology_name"])
      puts tech0
      (0...row["avail"].size).each do |i|
        new_name = "#{row["technology_name"]}-#{row["avail"][i]}"
        puts new_name
        tech = Technology.find_by_name(new_name)
        Technology.destroy(tech.id) if tech
        tech = tech0.duplicate(new_name)
        if row["avail"][i].to_i>end_year
          tech.set_list = (tech.set_list - ["P"]).join(",") #deactivate technology
          tech.save!
        end
        %w{icap_bnd_fx avail fixed_cap}.each do |param|
          ParameterValue.destroy(tech.parameter_values.of(param).map(&:id))
        end
        ParameterValue.create(:parameter_id=>Parameter.find_by_name("avail").id,
                              :technology_id=>tech.id,
                              :value=>row["avail"][i],
                              :source=>"technology generator")
        %w{cost_icap cost_fom}.each do |param|
          tech.parameter_values.of(param).each do |pv|
            ParameterValue.update(pv.id, :value=>pv.value*row[param][i])
          end
        end
        param = "eff_flo"
        tech.parameter_values.of(param).each do |pv|
          unless pv.out_flow.pollutant?
            ParameterValue.update(pv.id, :value=>pv.value*row[param][i])
          end
        end
      end
    end
  end

  def fixed_production(commodity_name,year=2005)
    commodity = Commodity.find_by_name(commodity_name)
    total = commodity.produced_by.inject(0){|sum,t|
      fixed_cap = p_value("fixed_cap",:technology_id=>t,:year=>year)
      cap_act   = p_value("cap_act",:technology_id=>t)
      act_flo   = p_value("act_flo",:technology_id=>t,:commodity_id=>commodity)
      avail_factor = p_value("avail_factor",:technology_id=>t,:time_slice=>"AN")
      t_production = fixed_cap * cap_act * act_flo * avail_factor
      puts "#{t.name}: #{fixed_cap} x #{cap_act} x #{act_flo} x #{avail_factor}"
      sum + t_production
    }
    puts "Total: #{total}"
  end

  def p_value(parameter_name,attributes)
    param = Parameter.find_by_name(parameter_name)
    pv = ParameterValue.where(:parameter_id=>param).where(attributes).first
    return pv ? pv.value : param.default_value
  end

  # Create a fuel tech and its input/output if necessary
  def create_fuel_tech(input,output)

    #find_or_create commodities
    com = {}
    [input,output].each do |c|
      if Commodity.where(:name=>c).empty?
        com[c] = Commodity.create(:name=>c,:description=>"",:set_list=>"ENC,C")
      else
        com[c] = Commodity.find_by_name(c)
      end
    end

    #check if a fuel tech already exists?
    if (com[input].consumed_by & com[output].produced_by).size > 0
      return nil
    end

    t = Technology.new
    name = "TECH-" + output
    while Technology.find_by_name(name)
      name.succ!
    end
    t.name = name
    t.description = "Fuel tech"
    t.set_list = "FUELTECH"
    t.save
    fi = InFlow.create
    fi.commodities << com[input]
    t.flows << fi
    fo = OutFlow.create
    fo.commodities << com[output]
    t.flows << fo
    t.save
    p = Parameter.find_by_name("eff_flo")
    ParameterValue.create(:parameter  => p,
                          :technology => t,
                          :in_flow =>fi,
                          :out_flow =>fo,
                          :value => 1,
                          :source => "Fuel tech")
    t.flow_act = fi
    t
  end

  # Create a fuel tech and its input/output if necessary
  def batch_create_emissions_flows(input,output,coefficient=1,source="")
    i = Commodity.find_by_name(input)
    puts "input: #{i}"
    o = Commodity.find_by_name(output)
    puts "output: #{o}"
    p = Parameter.find_by_name("eff_flo")
    i.consumed_by.each do |t|
      if t.inputs.size == 1
        inflow_id = t.in_flows.first.id
        unless t.outputs.include?(o)

          #add out_flow
          flow = OutFlow.new(:technology_id => t.id)
          flow.commodities = [o]
          if flow.save
            puts "Create out_flow for #{t}"
          else
            flow.errors.each_full{|msg| puts "error " + msg }
          end
          outflow_id = flow.id

          #add coefficient
          attributes = Hash.new
          attributes[:parameter_id] = p.id
          attributes[:in_flow_id]   = inflow_id
          attributes[:out_flow_id]  = outflow_id
          attributes[:technology_id] = t.id
          attributes[:value]        = coefficient
          attributes[:source]       = source
          pv = ParameterValue.new(attributes)
          if pv.save
            puts "Create parameter_value eff_flo"
          else
            pv.errors.each_full{|msg| puts "error " + msg }
          end

        end
      end
    end
  end

  def batch_update_emissions_flows(input,output,coefficient=1,source=nil)
    i = Commodity.find_by_name(input)
    puts "input: #{i}"
    o = Commodity.find_by_name(output)
    puts "output: #{o}"
    p = Parameter.find_by_name("eff_flo")
    i.consumed_by.each do |t|
      if t.inputs.size == 1
        t.out_flows.each do |f|
          if f.commodities.size==1 && f.commodities.include?(o)
            pv = ParameterValue.find(:first,:conditions=>{:parameter_id=>p.id,:out_flow_id=>f.id})
            if coefficient.to_s.starts_with("*")
              pv.update_attributes({:value => pv.value * coefficient[1..-1].to_f})
            else
              pv.update_attributes({:value => coefficient.to_f})
            end
            pv.update_attributes({:source => source}) if source
            puts "Parameter value of #{t} updated"
          end
        end
      end
    end
  end

end