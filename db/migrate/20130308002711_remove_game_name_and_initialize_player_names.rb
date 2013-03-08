class RemoveGameNameAndInitializePlayerNames < ActiveRecord::Migration
  def change
    remove_column :games, :name
    Game.reset_column_information
    Game.all.each do |game|
      game.update_attributes!(:red_player_name => 'red', :blue_player_name => 'blue')
    end
  end
end
