class CreateSnowballRepoGithubs < ActiveRecord::Migration
  def change
    create_table :snowball_repo_githubs do |t|
      t.integer :repo_id
      t.string :github_token
    end
  end
end
