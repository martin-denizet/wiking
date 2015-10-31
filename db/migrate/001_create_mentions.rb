class CreateMentions < ActiveRecord::Migration

    def self.up
        create_table :mentions do |t|
            t.column :mentioning_id,   :integer,   :null => false
            t.column :mentioning_type, :string,    :null => false, :limit => 30
            t.column :mentioned_id,    :integer,   :null => false
            t.column :created_on,      :timestamp, :null => false
        end
        add_index :mentions, [ :mentioning_type, :mentioning_id ], :name => :mentions_mentioning
        add_index :mentions,   :mentioned_id,                      :name => :mentions_mentioned
        add_index :mentions,   :created_on,                        :name => :mentions_created
    end

    def self.down
        drop_table :mentions
    end

end
