# Файл модели BedDay (models/bed_day.rb)
class BedDay < ActiveRecord::Base  # Наследование от базового класса ActiveRecord
  validates :date, presence: true
  validates :bed_index, inclusion: { in: 1..23 } # Теперь до 23 коек
  
  validates_uniqueness_of :bed_index, scope: :date
  
  # Метод для проверки, доступна ли койка в этот день
def self.available_beds(date)
  transition_date = Date.new(2025, 8, 18)
  weekday = date.wday
  
  if date < transition_date
    # Старая логика
    [1, 3, 5].include?(weekday) ? 23 : 18
  else
    # Новая логика
    18
  end
end


end