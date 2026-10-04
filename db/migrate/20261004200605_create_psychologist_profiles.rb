class CreatePsychologistProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :psychologist_profiles do |t|
      t.references :user,
                   null: false,
                   foreign_key: true,
                   index: { unique: true }

      t.text :specialization, null: false
      t.integer :experience_years, null: false
      t.decimal :price_per_session, null: false
      t.integer :session_duration, null: false
      t.text :bio, null: false

      t.timestamps
    end
  end
end
