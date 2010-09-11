require 'test_helper'

class CombustionsControllerTest < ActionController::TestCase
  setup do
    @combustion = combustions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:combustions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create combustion" do
    assert_difference('Combustion.count') do
      post :create, :combustion => @combustion.attributes
    end

    assert_redirected_to combustion_path(assigns(:combustion))
  end

  test "should show combustion" do
    get :show, :id => @combustion.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @combustion.to_param
    assert_response :success
  end

  test "should update combustion" do
    put :update, :id => @combustion.to_param, :combustion => @combustion.attributes
    assert_redirected_to combustion_path(assigns(:combustion))
  end

  test "should destroy combustion" do
    assert_difference('Combustion.count', -1) do
      delete :destroy, :id => @combustion.to_param
    end

    assert_redirected_to combustions_path
  end
end
