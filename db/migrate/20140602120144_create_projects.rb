class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string :name,     :limit => 64, :null => false, :default => ""
      t.string :status, limit: 32
      t.string :category, limit: 32
      t.string :access,  limit: 8, default: "Public" # %w(Private Public Shared)
      t.string :background_info

      t.text    :description
      t.decimal :cost_estimate, precision: 12, scale: 2

      t.integer :user_id

      t.datetime :due_at
      t.datetime :deleted_at

      t.text :subscribed_users

      t.timestamps
    end

    add_index :projects, [:user_id, :name, :deleted_at], :unique => true, :name => 'project_id_name_deleted'
  end
end
