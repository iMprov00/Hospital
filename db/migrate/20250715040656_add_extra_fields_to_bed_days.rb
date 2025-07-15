class AddExtraFieldsToBedDays < ActiveRecord::Migration[8.0]
  def change
        add_column :bed_days, :medical_organization, :string
    add_column :bed_days, :phone, :string
    add_column :bed_days, :address, :string
  end
end
