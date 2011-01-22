class BaseSchema < Sequel::Migration
  def up
    create_table! :users do
      primary_key :id
      String :email, :unique => true, :null => false
      String :crypted_password
      String :salt
      timestamp :created_at
    end

    create_table! :projects do
      primary_key :id
      foreign_key :user_id, :users
      String :name
      Integer :tracker_id
      index :tracker_id
    end

    create_table! :subscriptions do
      primary_key :id
      foreign_key :project_id, :projects
      String :username
      String :status
      timestamp :created_at
    end

    create_table! :projects_subscriptions do
      foreign_key :project_id, :projects
      foreign_key :subscription_id, :subscriptions
      index [:project_id, :subscription_id]
    end
  end

  def down
    drop_table :users
    drop_table :projects
    drop_table :subscriptions
    drop_table :projects_subscriptions
  end
end

