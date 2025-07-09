class AddDiagnosisToBedDays < ActiveRecord::Migration[8.0]
  def change
    add_column :bed_days, :diagnosis_code, :string
    add_column :bed_days, :diagnosis_name, :string
  end
end
