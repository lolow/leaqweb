require 'spec_helper'

describe "dashboard" do

  before (:each) do
    @user =  Factory.create(:admin)
  end

  it "displays the user's username after successful login" do
    visit "/users/sign_in"
    fill_in "user_email", :with => @user.email
    fill_in "user_password", :with => @user.password
    click_button "Sign In"
    page.has_content?(@user.email)
  end
end