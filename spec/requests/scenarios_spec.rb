require 'spec_helper'

describe "Scenarios" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
    @res =  Factory(:energy_system)
    page.driver.post select_energy_systems_path, 'energy_system' => @res.id
  end

  describe "GET /scenarios" do
    it "displays scenarios (including default BASE)" do
      scenario = Factory(:scenario, energy_system: @res)
      get scenarios_path
      page.has_content?(scenario.name)
      page.has_content?("BASE")
    end
  end

end
