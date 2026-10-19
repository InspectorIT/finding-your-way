class RemoveStatusFromAppointments < ActiveRecord::Migration[8.1]
  def change
    remove_column :appointments, :status, :integer
  end
end
