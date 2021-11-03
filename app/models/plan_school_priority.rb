class PlanSchoolPriority
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: 'plan_school_priorities'

  field :dimension, type: String
  field :css_class, type: String
  field :no_dimension_order, type: Integer
  field :no_order, type: Integer
  field :name, type: String
  field :description, type: String
  field :objective, type: String
  field :actions, type: Array

  # Validations
  validates :institution, presence: true

  # Relationships
  has_many    :schools,           validate: false
  belongs_to  :institution,       validate: true

  default_scope -> { order_by(:no_dimension_order.asc, :no_order.asc) }

  def school_count
    count = 0
    search_params = {
        type: self.institution.type,
        state: self.institution.state
    }
    if self.institution.type == "Municipal"
      search_params[:city] = self.institution.city
    end
    @schools = School.where(search_params).with_plan
    @schools.each do |school|
      school.plan.each do |plan|
        if plan["priority_id"] == self.id
          count += 1
        end
      end
    end
    count
  end

  def to_s
    "#{dimension}/#{no_dimension_order} - #{name}"
  end

end