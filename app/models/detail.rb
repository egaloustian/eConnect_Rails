class Detail
  include Mongoid::Document
  field :Name, type: String
  field :SourceFile, type: String
  field :Date, type: String
  end

