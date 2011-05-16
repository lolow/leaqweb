# Copyright (c) 2009-2011, Public Research Center Henri Tudor.
# This file is licensed under the Affero General Public License
# version 3. See the COPYRIGHT file.

class EtemDebug
# collections of functions to debug the energy database

  attr_reader :errors

  def initialize
    self.clear
  end

  # Reinitialize errors and warnings
  def clear
    @errors = []
  end

  # Execute all checks
  def check_everything
    self.check_empty_flow
    self.check_presence_of_flow_act
    self.check_orphan_parameter_value
    self.check_disconnected_flow
    self.check_validity_of_flo_share_fx
    self.check_in_flow_and_demand
    self.check_dmd_and_demand
    self.check_orphan_demand
    self.check_presence_of_set
    self.check_demand_with_no_demand
    @errors
  end

  # Each technology must have a flow_act
  def check_presence_of_flow_act
    param = Parameter.find_by_name("flow_act")
    pv    = param.parameter_values.group(:technology_id).map(&:technology_id).sort
    tech  = Technology.all.map(&:id).sort
    unless pv==tech
      ids = (tech-pv)
      @errors << [:check_presence_of_flow_act,"Flow_act is missing for Technology with id: " + ids.join(",")]
    end
    @errors
  end

  # Check orphan parameter_values
  def check_orphan_parameter_value
    
    check = {:parameter_id=>Parameter,
             :technology_id=>Technology,
             :commodity_id=>Commodity,
             :in_flow_id=>InFlow,
             :out_flow_id=>OutFlow,
             :flow_id=>Flow
    }
    
    check.each { |field,klass|
      pv = ParameterValue.group(field).map(&field).compact
      pv_ids = pv - klass.select(:id).map(&:id)
      if pv_ids.size > 0
        ids = ParameterValue.where(field=>pv_ids).map(&:id)
        @errors << [:check_orphan_parameter_value,"Wrong value in #{field} for ParameterValue: " + ids.join(",")]
      end
    }
    @errors
  end

  def check_empty_flow
    ids = Flow.includes(:commodities).select{|f|f.commodities.size==0}.map(&:id)
    if ids.size > 0
      @errors << [:check_empty_flow,"Empty Flow : " + ids.join(",")]
    end
    @errors
  end

  def check_disconnected_flow
    param  = Parameter.find_by_name("eff_flo")
    pv  = param.parameter_values.group(:in_flow_id).map(&:in_flow_id)
    pv  += param.parameter_values.group(:out_flow_id).map(&:out_flow_id)
    pv.sort!
    flow  = Flow.all.map(&:id).sort
    unless pv==flow
      (flow-pv).collect{|f|
        @errors << [:check_disconnected_flow,"Flow #{f} is disconnected - Please define eff_flo parameters"]
      }
    end
    @errors
  end

  def check_validity_of_flo_share_fx
    param  = Parameter.find_by_name("flo_share_fx")
    param.parameter_values.group(:flow_id).sum(:value).each { |f,sum|
      unless sum<=1
        @errors << [:check_validity_of_flo_share_fx,"Sum of 'flo_share_fx' is greater than 1 for Technology #{Flow.find(f).technology_id} and its Flow #{f}"]
      end
    }
    @errors
  end

  def check_in_flow_and_demand
    demands = Commodity.activated.tagged_with("DEM").map(&:id)
    inflows = InFlow.all.collect{|f|f.commodities.map(&:id)}.flatten.uniq
    ids = demands & inflows
    if ids.size > 0
      @errors << [:check_in_flow_and_demand,"InFlows should not contain demand Commodity: " + ids.join(",")]
    end
    @errors
  end

  def check_dmd_and_demand
    demands = Commodity.activated.demands.map(&:id)
    techs   = OutFlow.joins(:commodities).where('commodities.id'=>demands).group(:technology_id).map(&:technology_id)
    dmd     = Technology.tagged_with("DMD").map(&:id)
    ids = techs - dmd
    if ids.size > 0
      @errors << [:check_dmd_and_demand,"DMD set should contain Technology: " + ids.join(",")]
    end
    @errors
  end

    def check_orphan_demand
    Commodity.activated.demands.each do |dem|
      if dem.produced_by.size == 0
        @errors << [:check_dmd_and_demand,"No producer for commodity DEM " + dem.name]
      end
    end
    @errors
  end

  def check_demand_with_no_demand
    Commodity.activated.demands.each do |dem|
      if ParameterValue.of("demand").where(:commodity_id=>dem.id).count == 0
        @errors << [:check_demand_with_no_demand,"No demand value for demand " + dem.name]
      end
    end
    @errors
  end

  def check_presence_of_set
    ids = Commodity.activated.select{|c|c.sets.empty?}.map(&:id)
    if ids.size > 0
      @errors << [:check_presence_of_set,"No sets has been defined for Commodity:" + ids.join(",")]
    end
  end

end
