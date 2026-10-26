class ChangeUsersRoleToString < ActiveRecord::Migration[8.1]
  def up
    rename_column :users, :role, :role_integer

    add_column :users, :role, :string, null: false, default: "client"

    execute <<~SQL
      UPDATE users
      SET role = CASE role_integer
        WHEN 0 THEN 'client'
        WHEN 1 THEN 'psychologist'
        WHEN 2 THEN 'admin'
        ELSE 'client'
      END
    SQL

    remove_column :users, :role_integer
  end

  def down
    rename_column :users, :role, :role_string

    add_column :users, :role, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE users
      SET role = CASE role_string
        WHEN 'client' THEN 0
        WHEN 'psychologist' THEN 1
        WHEN 'admin' THEN 2
        ELSE 0
      END
    SQL

    remove_column :users, :role_string
  end
end
