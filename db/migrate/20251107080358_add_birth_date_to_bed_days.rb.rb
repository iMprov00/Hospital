class AddBirthDateToBedDays < ActiveRecord::Migration[8.0]
  def change
    add_column :bed_days, :birth_date, :date
  end
end
