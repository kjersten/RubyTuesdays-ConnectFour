class AddPlayerNames < ActiveRecord::Migration
  def up
    change_table :games do |t|
      t.string   :name
      t.string   :red_player_name
      t.string   :blue_player_name
    end
  end

  def down
    change_table :games do |t|
      t.remove   :name, :red_player_name, :blue_player_name
    end
  end

end
