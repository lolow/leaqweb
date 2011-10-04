require 'spec_helper'

describe "Aggregates" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  describe "GET /aggregates" do
    it "displays aggregates" do
      agg = Factory(:aggregate)
      get aggregates_path
      page.has_content?(agg.name)
    end
  end

end
