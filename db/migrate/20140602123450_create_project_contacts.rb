class CreateProjectContacts < ActiveRecord::Migration
  def change
    create_table :project_contacts do |t|
      t.integer :project_id
      t.integer :contact_id
      t.timestamps
    end

    add_index :project_contacts, [:project_id, :contact_id]
    add_index :project_contacts, :contact_id
    add_index :project_contacts, :project_id
  end
end
