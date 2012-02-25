require 'spec_helper'

describe "Combustions" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  describe "GET /combustions" do
    it "displays combustions" do
      combustion = Factory(:combustion)
      get combustions_path
      page.has_content?(combustion.fuel)
      page.has_content?(combustion.pollutant)
    end
  end

end
