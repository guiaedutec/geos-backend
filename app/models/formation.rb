class Formation
    include Mongoid::Document
    include Mongoid::Timestamps
    store_in collection: "formations"
    field :name, type: String
end