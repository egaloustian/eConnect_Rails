require 'test_helper'

class EconnectsControllerTest < ActionController::TestCase
  setup do
    @econnect = econnects(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:econnects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create econnect" do
    assert_difference('Econnect.count') do
      post :create, econnect: { Account: @econnect.Account, AggAccount: @econnect.AggAccount, AggSum: @econnect.AggSum, BSSI_Intercompany: @econnect.BSSI_Intercompany, BSSI_Max: @econnect.BSSI_Max, BSSI_facility: @econnect.BSSI_facility, BatchID: @econnect.BatchID, Carrier: @econnect.Carrier, CompanyAlloc: @econnect.CompanyAlloc, CompanyReqOrg: @econnect.CompanyReqOrg, Delivery: @econnect.Delivery, DeptAlloc: @econnect.DeptAlloc, Description: @econnect.Description, DivAlloc: @econnect.DivAlloc, DocDate: @econnect.DocDate, DocNum: @econnect.DocNum, DocType: @econnect.DocType, JournaAmt: @econnect.JournaAmt, JournalAcctCode: @econnect.JournalAcctCode, PONum: @econnect.PONum, PurchaseAmt: @econnect.PurchaseAmt, RemittoID: @econnect.RemittoID, ShaKey: @econnect.ShaKey, SourceFile: @econnect.SourceFile, Vendor: @econnect.Vendor, Voucher: @econnect.Voucher }
    end

    assert_redirected_to econnect_path(assigns(:econnect))
  end

  test "should show econnect" do
    get :show, id: @econnect
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @econnect
    assert_response :success
  end

  test "should update econnect" do
    patch :update, id: @econnect, econnect: { Account: @econnect.Account, AggAccount: @econnect.AggAccount, AggSum: @econnect.AggSum, BSSI_Intercompany: @econnect.BSSI_Intercompany, BSSI_Max: @econnect.BSSI_Max, BSSI_facility: @econnect.BSSI_facility, BatchID: @econnect.BatchID, Carrier: @econnect.Carrier, CompanyAlloc: @econnect.CompanyAlloc, CompanyReqOrg: @econnect.CompanyReqOrg, Delivery: @econnect.Delivery, DeptAlloc: @econnect.DeptAlloc, Description: @econnect.Description, DivAlloc: @econnect.DivAlloc, DocDate: @econnect.DocDate, DocNum: @econnect.DocNum, DocType: @econnect.DocType, JournaAmt: @econnect.JournaAmt, JournalAcctCode: @econnect.JournalAcctCode, PONum: @econnect.PONum, PurchaseAmt: @econnect.PurchaseAmt, RemittoID: @econnect.RemittoID, ShaKey: @econnect.ShaKey, SourceFile: @econnect.SourceFile, Vendor: @econnect.Vendor, Voucher: @econnect.Voucher }
    assert_redirected_to econnect_path(assigns(:econnect))
  end

  test "should destroy econnect" do
    assert_difference('Econnect.count', -1) do
      delete :destroy, id: @econnect
    end

    assert_redirected_to econnects_path
  end
end
