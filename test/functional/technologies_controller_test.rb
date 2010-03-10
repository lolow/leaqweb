require 'test_helper'

class TechnologiesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:technologies)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create technology" do
    assert_difference('Technology.count') do
      post :create, :technology => { }
    end

    assert_redirected_to technology_path(assigns(:technology))
  end

  test "should show technology" do
    get :show, :id => technologies(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => technologies(:one).to_param
    assert_response :success
  end

  test "should update technology" do
    put :update, :id => technologies(:one).to_param, :technology => { }
    assert_redirected_to technology_path(assigns(:technology))
  end

  test "should destroy technology" do
    assert_difference('Technology.count', -1) do
      delete :destroy, :id => technologies(:one).to_param
    end

    assert_redirected_to technologies_path
  end
end
