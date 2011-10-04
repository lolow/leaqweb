require 'spec_helper'

describe "DemandDrivers" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  describe "GET /demand_drivers" do
    it "displays demand drivers" do
      dd = Factory(:demand_driver)
      get demand_drivers_path
      page.has_content?(dd.name)
    end
  end
end
