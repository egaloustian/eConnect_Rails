class Header
  include Mongoid::Document
  field :BatchID, type: String
  field :VoucherNo, type: Integer
  field :Payables, type: String
  field :DocType, type: String
  field :Description, type: String
  field :Vendor, type: String
  field :RemitToID, type: String
  field :DocDate, type: Time
  field :DocNumber, type: String
  field :PurchaseAmount, type: Float
  field :PostingDate, type: Time
  field :PO, type: String
  field :BSSI_Facility, type: String
  field :BSSI_Department, type: String
  field :BSSI_Accountsub, type: String
  field :BSSI_Intercompany, type: String
  field :Carrier, type: String
  field :FileName, type: String
  end

