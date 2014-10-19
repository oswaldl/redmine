class CreateSnowballProjectVotes < ActiveRecord::Migration
  def change
    create_table :snowball_project_votes do |t|
      # t.integer :vote_project_id
      # t.integer :vote_count, :default => 0
      # t.string :vote_description

      t.integer :issue_id
      t.integer :user_id
      t.integer :point, :default => 1
    end
  end
end
