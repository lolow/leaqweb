require 'spec_helper'

describe "TechnologySets" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
    @res =  Factory(:energy_system)
    page.driver.post select_energy_systems_path, 'energy_system' => @res.id
  end

  describe "GET /technology_sets" do
    it "displays technology_sets" do
      technology_set = Factory(:technology_set, energy_system: @res)
      get technology_sets_path
      page.has_content?(technology_set.name)
    end
  end

end
