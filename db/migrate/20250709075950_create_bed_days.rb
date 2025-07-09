# Файл миграции для создания таблицы bed_days
class CreateBedDays < ActiveRecord::Migration[8.0]  # Наследование от класса миграции для Rails 8.0
  def change  # Основной метод миграции
    create_table :bed_days do |t|  # Создание таблицы bed_days с блоком описания столбцов
      t.date :date, null: false  # Столбец даты (обязательный)
      t.integer :bed_index, null: false  # Номер койки (1-20, обязательный)
      t.string :patient_name  # Имя пациентки (если занято, может быть NULL)
      t.boolean :occupied, default: false  # Флаг занятости (по умолчанию false)
      
      t.timestamps  # Автоматически добавляет created_at и updated_at
    end

    # Создание составного индекса для обеспечения уникальности пары date+bed_index
    add_index :bed_days, [:date, :bed_index], unique: true
  end
end