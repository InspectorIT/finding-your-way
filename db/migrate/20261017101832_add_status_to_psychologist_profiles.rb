class AddStatusToPsychologistProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :psychologist_profiles, :status, :integer, default: 0, null: false
  end
end
