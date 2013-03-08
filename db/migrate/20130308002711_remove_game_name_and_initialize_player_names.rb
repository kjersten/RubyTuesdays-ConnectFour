class RemoveGameNameAndInitializePlayerNames < ActiveRecord::Migration
  def up
    change_table :games do |t|
      t.remove   :name
    end
    Game.reset_column_information
    Game.all.each do |game|
      game.update_attributes!(:red_player_name => 'red', :blue_player_name => 'blue')
    end
  end

  def down
    change_table :games do |t|
      t.string   :name
    end
  end

end
