# Файл модели BedDay (models/bed_day.rb)
class BedDay < ActiveRecord::Base  # Наследование от базового класса ActiveRecord
  validates :date, presence: true
  validates :bed_index, inclusion: { in: 1..23 } # Теперь до 23 коек
  
  validates_uniqueness_of :bed_index, scope: :date
  
  # Метод для проверки, доступна ли койка в этот день
  def self.available_beds(date)
    weekday = date.wday
    if [1, 3, 5].include?(weekday) # Понедельник, среда, пятница
      23
    else
      18
    end
  end
end