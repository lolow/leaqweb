require 'spec_helper'

describe "Commodities" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  describe "GET /commodities" do
    it "displays commodities" do
      commodity = Factory(:demand)
      get commodities_path
      page.has_content?(commodity.name)
    end
  end

  describe "GET /commodities/id" do
    it "displays demand" do
      commodity = Factory(:demand)
      get commodity_path(commodity.id)
      page.has_content?(commodity.name)
      page.has_content?("Demand")
    end
  end

end
