require 'spec_helper'

describe "StoredQueries" do

  before (:each) do
    @user =  Factory.create(:admin)
    page.driver.post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  describe "GET /stored_queries" do
    it "displays stored queries" do
      sq = Factory(:stored_query)
      get stored_queries_path
      page.has_content?(sq.name)
    end
  end
end
