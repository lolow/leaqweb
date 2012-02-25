require 'spec_helper'

describe "CommoditySets" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
    @res =  Factory(:energy_system)
    page.driver.post select_energy_systems_path, 'energy_system' => @res.id
  end

  describe "GET /commodity_sets" do
    it "displays commodity_sets" do
      agg = Factory(:commodity_set, energy_system: @res)
      get commodity_sets_path
      page.has_content?(agg.name)
    end
  end

end
