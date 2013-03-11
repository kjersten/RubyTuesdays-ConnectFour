class GamesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  # Display a list of all games
  #   Should set the @games instance variable to a list of all games
  #
  # @verb GET
  # @path /games
  def index
    @games = Game.all
  end

  # Show a form for creating a new game
  #   Should set the @game instance variable to a new, unsaved game
  #
  # @verb GET
  # @path /games/new
  def new
    @game = Game.new
  end

  # Shows game with given :id
  #   Should set the @game variable to the given game object
  #
  # @verb GET
  # @path /games/:id
  def show
    @game = Game.find params[:id] 
  end

  # Creates a game recourse
  #
  # @verb POST
  # @path /games
  def create
    @game = Game.new params[:game]
    if @game.save
      redirect_to @game, :notice => "Game created!"
    else 
      render :action => 'new'
    end
  end

  # Destroys given game
  #
  # @verb DELETE
  # @path /games/:id
  def destroy
    @game = Game.find params[:id]
    @game.destroy
    redirect_to(games_path, :notice => 'Game deleted!')
  end


  # Makes a move
  #
  # @verb POST
  # @path /games/:id/move
  # @param [String] :player The player making the move
  # @param [Int] :column The column the move is made on
  def move
    @game = Game.find params[:id]
    if @game.make_move params[:column], params[:player]
      redirect_to @game, :status => '200'
    else 
      render :text => "400 Not Successful", :status => 400
    end
  end

  private
 
  def record_not_found
    render :text => "404 Not Found", :status => 404
  end

end

