class AddReviewMetadataAndAppointmentHistory < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :anonymous,
               :boolean, default: false, null: false

    add_column :comments, :verified_client,
               :boolean, default: false, null: false

    # Разрешаем хранить несколько завершённых записей
    # одного пользователя, сохраняя уникальность слота.
    remove_index :appointments,
                 name: "index_appointments_on_client_id"

    add_index :appointments, :client_id
  end
end
