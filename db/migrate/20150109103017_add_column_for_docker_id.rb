class AddColumnForDockerId < ActiveRecord::Migration
  def change
  	add_column :domains, :docker_id, :string
  end
end
