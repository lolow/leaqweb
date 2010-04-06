require 'test_helper'

class SimulationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:simulations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create simulation" do
    assert_difference('Simulation.count') do
      post :create, :simulation => { }
    end

    assert_redirected_to simulation_path(assigns(:simulation))
  end

  test "should show simulation" do
    get :show, :id => simulations(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => simulations(:one).to_param
    assert_response :success
  end

  test "should update simulation" do
    put :update, :id => simulations(:one).to_param, :simulation => { }
    assert_redirected_to simulation_path(assigns(:simulation))
  end

  test "should destroy simulation" do
    assert_difference('Simulation.count', -1) do
      delete :destroy, :id => simulations(:one).to_param
    end

    assert_redirected_to simulations_path
  end
end
