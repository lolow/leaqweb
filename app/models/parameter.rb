class Parameter < ActiveRecord::Base

  versioned

  has_many :parameter_values

  validates :name, :presence => true, :uniqueness => true

  SIGNATURE = {
    "com_net_bnd_up_t" => %w{year commodity},
    "com_net_bnd_up_ts" => %w{year time_slice commodity},
    "act_bnd_lo"       => %w{year time_slice technology},
    "act_bnd_fx"       => %w{year time_slice technology},
    "act_bnd_up"       => %w{year time_slice technology},
    "peak_reserve"     => %w{year time_slice commodity},
    "exp_bnd_lo"       => %w{year time_slice commodity},
    "exp_bnd_fx"       => %w{year time_slice commodity},
    "exp_bnd_up"       => %w{year time_slice commodity},
    "imp_bnd_lo"       => %w{year time_slice commodity},
    "imp_bnd_fx"       => %w{year time_slice commodity},
    "imp_bnd_up"       => %w{year time_slice commodity},
    "flo_share_lo"     => %w{flow commodity},
    "flo_share_fx"     => %w{flow commodity},
    "flo_share_up"     => %w{flow commodity},
    "flo_bnd_lo"       => %w{flow year time_slice},
    "flo_bnd_fx"       => %w{flow year time_slice},
    "flo_bnd_up"       => %w{flow year time_slice},
    "fraction"         => %w{time_slice},
    "demand"           => %w{year commodity},
    "avail_factor"     => %w{year time_slice technology},
    "cost_exp"         => %w{year time_slice commodity},
    "cost_imp"         => %w{year time_slice commodity},
    "cost_fom"         => %w{year technology},
    "cost_vom"         => %w{year technology},
    "cost_icap"        => %w{year technology},
    "icap_bnd_lo"      => %w{year technology},
    "icap_bnd_fx"      => %w{year technology},
    "icap_bnd_up"      => %w{year technology},
    "cap_bnd_lo"       => %w{year technology},
    "cap_bnd_fx"       => %w{year technology},
    "cap_bnd_up"       => %w{year technology},
    "frac_dem"         => %w{time_slice commodity},
    "eff_flo"          => %w{in_flow out_flow},
    "life"             => %w{technology},
    "avail"            => %w{technology},
    "cap_act"          => %w{technology},
    "act_flo"          => %w{technology commodity},
    "network_efficiency" => %w{commodity},
    "peak_prod"        => %w{technology time_slice commodity},
    "fixed_cap"        => %w{year technology},
    "cost_delivery"    => %w{year time_slice technology commodity},
    "flow_act"         => %w{technology},
    "nb_periods"       => nil,
    "period_length"    => nil,
    "discount_rate"    => nil
  }
  
  def to_s
    name
  end
  
end
