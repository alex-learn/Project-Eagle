class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.text :email
      t.text :f_name
      t.text :l_name
      t.text :device_name
      t.text :os_version
      t.text :app_version
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
