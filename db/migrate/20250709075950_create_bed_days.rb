class CreateBedDays < ActiveRecord::Migration[8.0]
  def change
        create_table :bed_days do |t|
      t.date :date, null: false
      t.integer :bed_index, null: false  # Номер койки (1-20)
      t.string :patient_name             # Имя пациентки (если занято)
      t.boolean :occupied, default: false
      
      t.timestamps
    end

    add_index :bed_days, [:date, :bed_index], unique: true
  end
end
