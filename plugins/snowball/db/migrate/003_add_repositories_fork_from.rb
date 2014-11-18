class AddRepositoriesForkFrom < ActiveRecord::Migration

    def self.up
        add_column :repositories, :fork_from, :string
    end

    def self.down
        remove_column :repositories, :fork_from
    end

end
