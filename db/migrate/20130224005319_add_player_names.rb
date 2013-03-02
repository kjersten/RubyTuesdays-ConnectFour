class AddPlayerNames < ActiveRecord::Migration
  def change
    change_table :games do |t|
      t.string   :name
      t.string   :red_player_name
      t.string   :blue_player_name
    end
  end

end
