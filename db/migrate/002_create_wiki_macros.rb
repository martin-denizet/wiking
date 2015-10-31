class CreateWikiMacros < ActiveRecord::Migration

    def self.up
        create_table :wiki_macros do |t|
            t.column :name,        :string, :null => false, :limit => 30
            t.column :description, :string, :null => false
            t.column :content,     :text,   :null => false
        end
        add_index :wiki_macros, [ :name ], :name => :wiki_macros_name
    end

    def self.down
        drop_table :wiki_macros
    end

end
