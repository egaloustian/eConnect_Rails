class TestModel
  include Mongoid::Document
  field :first, type: String
  field :last, type: String
  field :gender, type: String
  field :age, type: Integer
end
