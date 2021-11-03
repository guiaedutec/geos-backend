FactoryGirl.define do
  factory :school do
    name { "#{Faker::Company.name} school" }
    inep_code 1111111
    staff_count 30
    student_diurnal_count 1
    student_vespertine_count 2
    student_nocturnal_count 7
    student_full_count 15

    private false
    type 'Federal'
    location_type '?'
    sample false
    observations 'demais!'

    association(:city)
    association(:manager)
  end
end
