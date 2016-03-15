class Detail
  include Mongoid::Document
  field :BatchID, type: String
  field :VoucherNo, type: String
  field :Account, type: String
  field :DistType, type: String
  field :DebitAmt, type: Float
  field :CreditAmt, type: Float
  field :AccountAgg, type: String
  field :Vendor, type: String
  field :FileName, type: String
  end

