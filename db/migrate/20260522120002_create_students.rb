class CreateStudents < ActiveRecord::Migration[7.2]
  def change
    create_table :students do |t|
      t.string :first_name, null: false
      t.string :last_name,  null: false
      t.string :surname,    null: false
      t.references :school, null: false, foreign_key: true
      t.references :class,  null: false, foreign_key: { to_table: :classes }
      t.string :auth_token

      t.timestamps
    end

    add_index :students, :auth_token, unique: true
  end
end
