class EnforceOneAppointmentPerClient < ActiveRecord::Migration[8.1]
  def up
    remove_index :appointments,
                 name: "index_appointments_on_client_id"

    add_index :appointments,
              :client_id,
              unique: true,
              name: "index_appointments_on_client_id"
  end

  def down
    remove_index :appointments,
                 name: "index_appointments_on_client_id"

    add_index :appointments,
              :client_id,
              name: "index_appointments_on_client_id"
  end
end
