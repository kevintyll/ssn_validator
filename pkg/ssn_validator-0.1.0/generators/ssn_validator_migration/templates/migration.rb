class CreateSsnValidatorTables < ActiveRecord::Migration
  
  def self.up
    create_table :ssn_high_group_codes do |t|
      t.date      :as_of
      t.string    :area
      t.string    :group
      t.timestamps
    end
    
    add_index :ssn_high_group_codes, [:area]
    add_index :ssn_high_group_codes, [:area, :group]
  end
  
  def self.down
    drop_table :ssn_high_group_codes
  end
end
