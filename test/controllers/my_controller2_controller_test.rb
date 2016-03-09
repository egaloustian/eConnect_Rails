require 'test_helper'

class MyController2ControllerTest < ActionController::TestCase
  test "should get actionA" do
    get :actionA
    assert_response :success
  end

  test "should get actionB" do
    get :actionB
    assert_response :success
  end

  test "should get actionC" do
    get :actionC
    assert_response :success
  end

end
