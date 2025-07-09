# models/bed_day.rb
class BedDay < ActiveRecord::Base
  validates :date, presence: true
  validates :bed_index, inclusion: { in: 1..20 }
  validates_uniqueness_of :bed_index, scope: :date
end