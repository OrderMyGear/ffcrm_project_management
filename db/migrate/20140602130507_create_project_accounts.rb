class CreateProjectAccounts < ActiveRecord::Migration
  def change
    create_table :project_accounts do |t|
      t.integer :project_id
      t.integer :account_id

      t.timestamps
    end

    add_index :project_accounts, :project_id
    add_index :project_accounts, :account_id
  end
end
