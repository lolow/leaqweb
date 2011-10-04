require 'spec_helper'

describe "Technologies" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  describe "GET /technologies" do
    it "displays technologies" do
      technology = Factory(:demand_device)
      get technologies_path
      page.has_content?(technology.name)
    end
  end
end
