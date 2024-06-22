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

ActiveRecord::Schema[7.1].define(version: 2023_08_21_084507) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.string "type", null: false
    t.integer "category", null: false
    t.string "name"
    t.text "description"
    t.datetime "start_time", null: false
    t.datetime "end_time"
    t.jsonb "extras"
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.boolean "open_end", default: false, null: false
    t.string "time_format"
    t.index ["category"], name: "index_events_on_category"
    t.index ["end_time"], name: "index_events_on_end_time"
    t.index ["extras"], name: "index_events_on_extras", using: :gin
    t.index ["start_time"], name: "index_events_on_start_time"
    t.index ["type"], name: "index_events_on_type"
  end

  create_table "wallets", force: :cascade do |t|
    t.string "stake_address"
    t.datetime "last_connected_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stake_address"], name: "index_wallets_on_stake_address"
  end

end
