class ParameterValue < ActiveRecord::Base

  versioned

  belongs_to :parameter
  belongs_to :technology
  belongs_to :commodity
  belongs_to :flow
  belongs_to :out_flow
  belongs_to :in_flow

  validates :value, :presence => true, :numericality => true
  validates :parameter, :presence => true
  validates :year, :numericality => {:only_integer => true, :minimum => -1}, :allow_nil => true
  validates :time_slice, :inclusion => { :in => %w(AN IN ID SN SD WN WD) }, :allow_nil => true

  scope :of, lambda { |names| joins(:parameter).where("parameters.name"=>names).order("parameters.name") }
  scope :technology, lambda { |tech| where(:technology_id=>tech) }

  SIGNATURE = {
    "com_net_bnd_up_t" => %w{year commodity_id},
    "com_net_bnd_up_ts"=> %w{year time_slice commodity_id},
    "act_bnd_lo"       => %w{year time_slice technology_id},
    "act_bnd_fx"       => %w{year time_slice technology_id},
    "act_bnd_up"       => %w{year time_slice technology_id},
    "peak_reserve"     => %w{year time_slice commodity_id},
    "exp_bnd_lo"       => %w{year time_slice commodity_id},
    "exp_bnd_fx"       => %w{year time_slice commodity_id},
    "exp_bnd_up"       => %w{year time_slice commodity_id},
    "imp_bnd_lo"       => %w{year time_slice commodity_id},
    "imp_bnd_fx"       => %w{year time_slice commodity_id},
    "imp_bnd_up"       => %w{year time_slice commodity_id},
    "flo_share_lo"     => %w{flow commodity_id},
    "flo_share_fx"     => %w{flow commodity_id},
    "flo_share_up"     => %w{flow commodity_id},
    "flo_bnd_lo"       => %w{flow year time_slice},
    "flo_bnd_fx"       => %w{flow year time_slice},
    "flo_bnd_up"       => %w{flow year time_slice},
    "fraction"         => %w{time_slice},
    "demand"           => %w{year commodity_id},
    "avail_factor"     => %w{year time_slice technology_id},
    "cost_exp"         => %w{year time_slice commodity_id},
    "cost_imp"         => %w{year time_slice commodity_id},
    "cost_fom"         => %w{year technology_id},
    "cost_vom"         => %w{year technology_id},
    "cost_icap"        => %w{year technology_id},
    "icap_bnd_lo"      => %w{year technology_id},
    "icap_bnd_fx"      => %w{year technology_id},
    "icap_bnd_up"      => %w{year technology_id},
    "cap_bnd_lo"       => %w{year technology_id},
    "cap_bnd_fx"       => %w{year technology_id},
    "cap_bnd_up"       => %w{year technology_id},
    "frac_dem"         => %w{time_slice commodity_id},
    "eff_flo"          => %w{in_flow_id out_flow_id},
    "life"             => %w{technology_id},
    "avail"            => %w{technology_id},
    "cap_act"          => %w{technology_id},
    "act_flo"          => %w{technology_id commodity_id},
    "network_efficiency" => %w{commodity_id},
    "peak_prod"        => %w{technology time_slice commodity_id},
    "fixed_cap"        => %w{year technology_id},
    "cost_delivery"    => %w{year time_slice technology_id commodity_id},
    "flow_act"         => %w{technology_id},
    "nb_periods"       => nil,
    "period_length"    => nil,
    "discount_rate"    => nil
  }

  def self.create_update(attributes)
    case attributes[:parameter_id].class
    when Integer
      parameter = Parameter.find(attributes[:parameter_id])
    when Parameter
      parameter = attributes[:parameter_id]
    else
      return nil
    end
    signature = SIGNATURE[parameter.name]
    pv_index = Hash[*h.select{|key,value| signature.include? key.to_s}.flatten]
    query=parameter.parameter_values.where(pv_index)
    if query.size >= 1
      ParameterValue.update(query.map(&:id),attributes)
    else
      ParameterValue.create!(attributes)
    end
  end

end