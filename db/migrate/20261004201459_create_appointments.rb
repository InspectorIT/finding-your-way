class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :client,
                   null: false,
                   foreign_key: { to_table: :users }

      t.references :slot,
                   null: false,
                   foreign_key: true,
                   index: { unique: true }

      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
