require 'spec_helper'

describe "Markets" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  describe "GET /markets" do
    it "displays markets" do
      market = Factory(:market)
      get markets_path
      page.has_content?(market.name)
    end
  end

end
