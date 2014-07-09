class CreateProjectAssignees < ActiveRecord::Migration
  def change
    create_table :project_assignees do |t|
      t.integer :project_id
      t.integer :assignee_id
      t.timestamps
    end

    add_index :project_assignees, [:project_id, :assignee_id]
  end
end
