# Файл миграции для добавления полей диагноза
class AddDiagnosisToBedDays < ActiveRecord::Migration[8.0]  # Наследование от класса миграции для Rails 8.0
  def change  # Основной метод миграции
    # Добавление столбца для кода диагноза (строка)
    add_column :bed_days, :diagnosis_code, :string
    
    # Добавление столбца для названия диагноза (строка)
    add_column :bed_days, :diagnosis_name, :string
  end
end