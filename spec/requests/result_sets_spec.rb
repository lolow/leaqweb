require 'spec_helper'

describe "ResultSets" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  describe "GET /result_sets" do
    it "displays result_sets" do
      result_set = Factory(:result_set)
      get scenarios_path
      page.has_content?(result_set.name)
    end
  end
end
