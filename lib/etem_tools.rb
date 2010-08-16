#collections of functions to help the feeding of the database

module EtemTools

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