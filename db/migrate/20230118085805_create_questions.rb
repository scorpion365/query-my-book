class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.string :question
      t.text :context
      t.text :answer
      t.integer :ask_count, default: 0
      t.timestamps
    end
  end
end
