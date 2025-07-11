# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_09_090314) do
  create_table "bed_days", force: :cascade do |t|
    t.date "date", null: false
    t.integer "bed_index", null: false
    t.string "patient_name"
    t.boolean "occupied", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "diagnosis_code"
    t.string "diagnosis_name"
    t.index ["date", "bed_index"], name: "index_bed_days_on_date_and_bed_index", unique: true
  end
end
