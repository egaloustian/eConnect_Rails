class Header
  include Mongoid::Document
  field :batchid, type: String
  field :voucher, type: Integer
  field :description, type: String
  field :vendor, type: String
  field :remittoid, type: String
  field :docnumber, type: String
  field :ponumber, type: String
  field :purchaseamount, type: Float
  field :bssi_facility, type: String
  field :bssi_department, type: String
  field :bssi_accountsub, type: String
  field :bssi_intercompany, type: String
  field :carrier_handler, type: String
  field :postingdate, type: Time
  field :docdate, type: Time
  field :doctype, type: String
  field :payablesbatch, type: String
  field :sourceFile, type: String
  end

