class EducationalInstitution
    include Mongoid::Document
    include Mongoid::Timestamps
    store_in collection: "educational_institutions"
    field :name, type: String
end
  