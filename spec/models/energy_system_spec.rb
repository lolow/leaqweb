require 'spec_helper'

describe EnergySystem do
  describe ".last_year" do
    it "returns the last year of the time horizon" do
      res = Factory(:energy_system)
      res.last_year.should eq(res.first_year - 1 + (res.nb_periods * res.period_duration))
    end
  end
end
