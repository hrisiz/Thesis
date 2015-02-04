class AddPortColumnToDomains < ActiveRecord::Migration
  def change
	add_column :domains, :port, :bigint
  end
end
