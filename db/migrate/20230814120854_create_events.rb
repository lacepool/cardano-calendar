class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :type, index: true, null: false
      t.integer :category, index: true, null: false
      t.string :name
      t.text :description
      t.datetime :start_time, index: true, null: false
      t.datetime :end_time, index: true
      t.jsonb :extras, index: { using: 'gin' }

      t.timestamps default: -> { 'NOW()' }
    end
  end
end
