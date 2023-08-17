class AddColumnsToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :open_end, :boolean, null: false, default: false
    add_column :events, :time_format, :string
  end
end
