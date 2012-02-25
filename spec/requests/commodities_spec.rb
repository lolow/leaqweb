require 'spec_helper'

describe "Commodities" do

  before (:each) do
    @user =  Factory(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
    @res =  Factory(:energy_system)
    page.driver.post select_energy_systems_path, 'energy_system' => @res.id
  end

  describe "GET /commodities" do
    it "displays commodities" do
      commodity = Factory(:demand, energy_system: @res)
      get commodities_path
      page.has_content?(commodity.name)
    end
  end

  describe "GET /commodities/id" do
    it "displays demand" do
      commodity = Factory(:demand, energy_system: @res)
      get commodity_path(commodity.id)
      page.has_content?(commodity.name)
      page.has_content?("Demand")
    end
  end

end
