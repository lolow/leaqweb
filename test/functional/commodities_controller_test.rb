require 'test_helper'

class CommoditiesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:commodities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create commodity" do
    assert_difference('Commodity.count') do
      post :create, :commodity => { }
    end

    assert_redirected_to commodity_path(assigns(:commodity))
  end

  test "should show commodity" do
    get :show, :id => commodities(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => commodities(:one).to_param
    assert_response :success
  end

  test "should update commodity" do
    put :update, :id => commodities(:one).to_param, :commodity => { }
    assert_redirected_to commodity_path(assigns(:commodity))
  end

  test "should destroy commodity" do
    assert_difference('Commodity.count', -1) do
      delete :destroy, :id => commodities(:one).to_param
    end

    assert_redirected_to commodities_path
  end
end
