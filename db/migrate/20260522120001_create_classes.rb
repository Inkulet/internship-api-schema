class CreateClasses < ActiveRecord::Migration[7.2]
  def change
    create_table :classes do |t|
      t.integer :number, null: false
      t.string  :letter, null: false
      t.references :school, null: false, foreign_key: true
      t.integer :students_count, null: false, default: 0

      t.timestamps
    end

    add_index :classes, [:school_id, :number, :letter], unique: true
  end
end
