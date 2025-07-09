# Файл модели BedDay (models/bed_day.rb)
class BedDay < ActiveRecord::Base  # Наследование от базового класса ActiveRecord
  # Валидация наличия даты
  validates :date, presence: true
  
  # Валидация номера койки (должен быть в диапазоне 1-18)
  validates :bed_index, inclusion: { in: 1..18 } # Изменили на 18
  
  # Валидация уникальности номера койки в пределах одной даты
  validates_uniqueness_of :bed_index, scope: :date
end