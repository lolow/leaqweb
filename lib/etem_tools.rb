# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

#collections of functions to help the feeding of the database
#but should not be called by the application
require 'yaml'
require 'csv'

module EtemTools

  def generate_new_tech_from_csv(file,sector=nil,auto_combustion=true)
    # collect redundant infos
    list = %w{avail life af cap_act eff_flo flo_share_fx flo_share_up avail cost_vom cost_fom cost_icap avail_factor}
    param = {}
    list.each{|l|param[l]=Parameter.find_by_name(l)}
    if auto_combustion
      polls = ["CO2","N2O","CH4"].collect do |p|
        Commodity.find_by_name("#{p}-#{sector}")
      end
    else
      polls = CSV.read(file,{:col_sep=>"\t",:headers=>true,:skip_blanks=>true}).headers.select{|s|s[0,4]=="poll"}.collect{|s|s[5..-1]}.collect do |p|
        Commodity.find_by_name("#{p}")
      end
    end
    polls.compact!
    set_list = (sector=="PRD") ? "P" : "DMD,P"
    CSV.foreach(file,{:col_sep=>"\t",:headers=>true,:skip_blanks=>true}) do |row|
      tech_name = row["name"]
      puts tech_name
      tech = Technology.find_by_name(tech_name)
      Technology.destroy(tech.id) if tech
      tech = Technology.create!(:name => tech_name,
                                :description => row["description"],
                                :set_list => set_list)
      #Main flows
      in_flow = InFlow.create
      row["input"].split(",").each do |c|
        p c
        in_flow.commodities << Commodity.find_by_name(c)
        if row["share-"+c.downcase]
           ParameterValue.create!(:parameter => param["flo_share_fx"],
                            :technology    => tech,
                            :flow          => in_flow,
                            :commodity     => Commodity.find_by_name(c),
                            :value         => row["share-"+c.downcase],
                            :source        => "CRTE")
        end
      end
      out_flow = OutFlow.create
      outputs = row["output"].split(",")
      outputs.each do |c|
        out_flow.commodities << Commodity.find_by_name(c)
        if row["share-"+c.downcase]
           ParameterValue.create!(:parameter => param["flo_share_fx"],
                            :technology    => tech,
                            :flow          => out_flow,
                            :commodity     => Commodity.find_by_name(c),
                            :value         => row["share-"+c.downcase],
                            :source        => "CRTE")
        end
      end
      tech.flows << in_flow
      tech.flows << out_flow
      tech.flow_act = out_flow
      #Main parameters
      ParameterValue.create!(:parameter    => param["eff_flo"],
                             :technology    => tech,
                             :in_flow       => in_flow,
                             :out_flow      => out_flow,
                             :value         => row["eff_flo"],
                             :source        => "CRTE")
     ParameterValue.create!(:parameter     => param["avail"],
                            :technology    => tech,
                            :value         => row["avail"],
                            :source        => "CRTE [year]")
     ParameterValue.create!(:parameter     => param["cap_act"],
                            :technology    => tech,
                            :value         => row["cap_act"],
                            :source        => "CRTE") if row["cap_act"]
     ParameterValue.create!(:parameter     => param["life"],
                            :technology    => tech,
                            :value         => row["life"],
                            :source        => "CRTE [years]") if row["life"]
     ParameterValue.create!(:parameter     => param["cost_fom"],
                            :technology    => tech,
                            :year          => 0,
                            :value         => row["cost_fom"],
                            :source        => "CRTE") if row["cost_fom"]
     ParameterValue.create!(:parameter     => param["cost_vom"],
                            :technology    => tech,
                            :year          => 0,
                            :value         => row["cost_vom"],
                            :source        => "CRTE") if row["cost_vom"]
     ParameterValue.create!(:parameter     => param["cost_icap"],
                            :technology    => tech,
                            :year          => 0,
                            :value         => row["cost_icap"],
                            :source        => "CRTE") if row["cost_icap"]
     ParameterValue.create!(:parameter     => param["avail_factor"],
                            :technology    => tech,
                            :time_slice    => "AN",
                            :year          => 2005,
                            :value         => row["avail_factor"],
                            :source        => "CRTE") if row["avail_factor"]
     ParameterValue.create!(:parameter     => param["flo_share_up"],
                            :technology    => tech,
                            :flow          => out_flow,
                            :commodity     => Commodity.find_by_name("HET"),
                            :value         => row["flo_share_up_het"],
                            :source        => "CRTE") if row["flo_share_up_het"]
      #Combustion factors
      if auto_combustion
        polls.each do |p|
          out_flow = OutFlow.create
          out_flow.commodities << p
          tech.flows << out_flow
          coef = tech.combustion_factor(in_flow,out_flow)
          ParameterValue.create(:parameter   => param["eff_flo"],
                                :technology    => tech,
                                :in_flow       => in_flow,
                                :out_flow      => out_flow,
                                :value         => coef,
                                :source        => "Combustion coefficients")
        end
      else
      # specific pollutant
        
        polls.each do |p|
          puts "poll-" + p.name.downcase
          out_flow = OutFlow.create
          out_flow.commodities << p
          tech.flows << out_flow
          ParameterValue.create(:parameter   => param["eff_flo"],
                                :technology    => tech,
                                :in_flow       => in_flow,
                                :out_flow      => out_flow,
                                :value         => row["poll-"+p.name.downcase],
                                :source        => "CRTE")
        end
      end
    end
  end

  def generate_existing_technology(file,sector=nil)
    fixed_cap = Parameter.find_by_name("fixed_cap")
    life      = Parameter.find_by_name("life")
    af        = Parameter.find_by_name("avail_factor")
    cap_act   = Parameter.find_by_name("cap_act")
    icap_bnd_fx  = Parameter.find_by_name("icap_bnd_fx")
    eff_flo      = Parameter.find_by_name("eff_flo")
    flo_share_fx = Parameter.find_by_name("flo_share_fx")
    polls = ["CO2","N2O","CH4"].collect do |p|
      Commodity.find_by_name("#{p}-#{sector}")
    end
    polls.compact!
    CSV.foreach(file,{:col_sep=>"\t",:headers=>true,:skip_blanks=>true}) do |row|
      tech_name = sector + "-" + row["name"]
      puts tech_name
      tech = Technology.find_by_name(tech_name)
      Technology.destroy(tech.id) if tech
      tech = Technology.create!(:name => tech_name,
                               :description => row["description"],
                               :set_list => "DMD,P")
      #Main flows
      in_flow = InFlow.create
      row["in_flow"].split("-").each do |c|
        in_flow.commodities << Commodity.find_by_name(c+"-"+sector)
      end
      out_flow = OutFlow.create
      outputs = row["out_flow"].split("-")
      outputs.each do |c|
        out_flow.commodities << Commodity.find_by_name(sector+"-"+c)
      end
      tech.flows << in_flow
      tech.flows << out_flow
      tech.flow_act = out_flow
      #Main parameters
      ParameterValue.create!(:parameter     => eff_flo,
                            :technology    => tech,
                            :in_flow       => in_flow,
                            :out_flow      => out_flow,
                            :value         => row["eff_flo"],
                            :source        => "CRTE")
      ParameterValue.create!(:parameter     => fixed_cap,
                            :technology    => tech,
                            :year          => 2005,
                            :value         => row["fixed_cap_2005"],
                            :source        => "CRTE " + row["cap_unit"])
      ParameterValue.create!(:parameter     => life,
                            :technology    => tech,
                            :value         => row["life"],
                            :source        => "CRTE [years]")
      ParameterValue.create!(:parameter     => fixed_cap,
                            :technology    => tech,
                            :year          => 2005 - 1 + row["life"].to_i,
                            :value         => 0,
                            :source        => "CRTE " + row["cap_unit"])
      ParameterValue.create!(:parameter     => af,
                            :technology    => tech,
                            :time_slice    => "AN",
                            :year          => 2005,
                            :value         => row["avail_factor"],
                            :source        => "CRTE")
      ParameterValue.create!(:parameter     => cap_act,
                            :technology    => tech,
                            :value         => row["cap_act"],
                            :source        => "CRTE " + row["cap_act_unit"])
      ParameterValue.create!(:parameter     => icap_bnd_fx,
                            :technology    => tech,
                            :year          => 0,
                            :value         => row["icap_bnd_fx"],
                            :source        => "CRTE " + row["cap_unit"])
      ParameterValue.create!(:parameter     => flo_share_fx,
                            :technology    => tech,
                            :flow          => out_flow,
                            :commodity     => out_flow.commodities.first,
                            :value         => row["share-out"],
                            :source        => "CRTE") if row["share-out"]
      ParameterValue.create!(:parameter     => flo_share_fx,
                            :technology    => tech,
                            :flow          => out_flow,
                            :commodity     => out_flow.commodities[1],
                            :value         => 1.0 - row["share-out"].to_f,
                            :source        => "CRTE" ) if row["share-out"]
      #Combustion factors
      polls.each do |p|
        out_flow = OutFlow.create
        out_flow.commodities << p
        tech.flows << out_flow
        coef = tech.combustion_factor(in_flow,out_flow)
        ParameterValue.create(:parameter   => eff_flo,
                              :technology    => tech,
                              :in_flow       => in_flow,
                              :out_flow      => out_flow,
                              :value         => coef,
                              :source        => "Combustion coefficients")
      end
    end 
  end

  def generate_new_technology(yml_file,end_year=2030)
    without_versioning do
      YAML.load_file(yml_file).each do |row|
        tech0 = Technology.find_by_name(row["technology_name"])
        puts tech0
        row["avail"].size.times.each do |i|
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
  end

  #display the fixed production of a commodity
  def fixed_production(commodity_name,year=2005)
    commodity = Commodity.find_by_name(commodity_name)
    total = commodity.produced_by.inject(0){|sum,t|
      fixed_cap = p_value("fixed_cap",:technology_id=>t,:year=>year)
      cap_act   = p_value("cap_act",:technology_id=>t)
      act_flo   = p_value("act_flo",:technology_id=>t,:commodity_id=>commodity)
      avail_factor = p_value("avail_factor",:technology_id=>t,:time_slice=>"AN")
      t_production = fixed_cap * cap_act * act_flo * avail_factor
      cost_fom = p_value("cost_fom",:technology_id=>t,:year=>0)
      cost_fom *= fixed_cap
      cost_vom = p_value("cost_vom",:technology_id=>t,:time_slice=>"AN",:year=>0)
      cost_vom *= t_production
      puts "#{t.name}: #{fixed_cap} x #{cap_act} x #{act_flo} x #{avail_factor} cost[fix=#{cost_fom},var=#{cost_vom}]"
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
    t.set_list = "FUELTECH,P"
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
  def batch_create_emissions_flows(input,output,coefficient=1,source="",name="%")
    i, o = get_in_out(input, output)
    p = Parameter.find_by_name("eff_flo")
    i.consumed_by.where(["name like ?",name]).each do |t|
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

  def update_all_combustion_factor
    Combustion.all.each do |comb|
      techs = (comb.fuel.consumed_by & comb.pollutant.produced_by)
      puts "#{comb.fuel}->#{comb.pollutant}: #{techs.size} technologies"
      techs.each do |t|
        fin  = t.in_flows.select{|f|f.commodities.include?(comb.fuel)}.first
        fout = t.out_flows.select{|f|f.commodities.include?(comb.pollutant)}.first
        t.combustion_factor(fin, fout)
      end
    end
    puts "done"
  end

    def batch_create_or_update_eff_flo(input,output,coefficient=1,source=nil,name="%")
    i, o = get_in_out(input, output)
    p = Parameter.find_by_name("eff_flo")
    i.consumed_by.where(["name like ?",name]).each do |t|
      if t.inputs.size == 1
        inflow_id = nil
        t.in_flows.each do |f|
          if f.commodities.size==1 && f.commodities.include?(i)
            inflow_id = f.id
          end
        end
        break unless inflow_id
        t.out_flows.each do |f|
          if f.commodities.size==1 && f.commodities.include?(o)
            pv = ParameterValue.where(:parameter_id=>p.id,:out_flow_id=>f.id).first
            if pv
              if coefficient.to_s.starts_with("*")
                pv.update_attributes({:value => pv.value * coefficient[1..-1].to_f})
              else
                pv.update_attributes({:value => coefficient})
              end
              pv.update_attributes({:source => source}) if source
              puts "Parameter value of #{t} updated"
            else
              #add coefficient
              attributes = Hash.new
              attributes[:parameter_id]  = p.id
              attributes[:in_flow_id]    = inflow_id
              attributes[:out_flow_id]   = f.id
              attributes[:technology_id] = t.id
              attributes[:value]         = coefficient
              attributes[:source]        = source
              pv = ParameterValue.new(attributes)
              if pv.save
                puts "Create parameter_value eff_flo for #{t}"
              else
                pv.errors.each_full{|msg| puts "error " + msg }
              end
            end
          end
        end
      end
    end
  end

  def get_in_out(input, output)
    i = Commodity.find_by_name(input)
    puts "input: #{i}"
    o = Commodity.find_by_name(output)
    puts "output: #{o}"
    return i, o
  end

  def without_versioning
    was_enabled = PaperTrail.enabled?
    PaperTrail.enabled = false
    begin
      yield
    ensure
      PaperTrail.enabled = was_enabled
    end
  end

end