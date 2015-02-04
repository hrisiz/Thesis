class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.integer :user_id
      t.string :domain_name
      t.string :domain
      t.timestamps null: false
    end
  end
end
