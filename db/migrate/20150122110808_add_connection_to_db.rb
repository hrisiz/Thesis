class AddConnectionToDb < ActiveRecord::Migration
  def change
  	add_column :domains, :docker_db_id, :string
  	add_column :domains, :db_port, :string
  end
end
