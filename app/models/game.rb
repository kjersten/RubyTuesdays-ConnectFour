class Game < ActiveRecord::Base
  # This includes the methods in mixins/game/board_mixin.rb as class methods.
  # Check this file out for some helpful functions!
  extend Game::BoardMixin
  include Game::BoardMixin

  ### Constants ###

  # These define the size of the board. Remember: we index from 0, so valid
  # board coordinates are between [0,0] to [NUM_COLUMNS - 1 , NUM_ROWS - 1]
  NUM_ROWS = 6
  NUM_COLUMNS = 7

  ### Associations ###
  serialize :board, JSON

  # Security (ActiveModel::MassAssignmentSecurity)
  attr_accessible :board, :created_at, :status, :current_player, :red_player_name, :blue_player_name

  ### Scopes ###
  scope :in_progress, where(:status => :in_progress)
  scope :finished,    where(:status => %w(red blue tie))
  scope :won, where(:status => %w(red blue))
  scope :tie, where(:status => :tie)

  ### Callbacks ###

  ### Validations ###
  validates_inclusion_of :status, :allow_blank => false,
                                  :in => %w(in_progress blue red tie)
  validates_with BoardValidator, :dimensions => [NUM_COLUMNS, NUM_ROWS]
  validates_presence_of [:red_player_name, :blue_player_name], :on => :create


  # Sets current_player to 'blue' if current_player has not been initialized
  def initialize(*args)
    super(*args)

    # initialize variables
    # NOTE: Add all initialization here!
    self.board = (0...NUM_COLUMNS).map{[]} unless self.board.present?
    self.current_player = 'blue' unless self.current_player.present?
    self.status = 'in_progress' unless self.status.present?
  end

  # Gets the next player
  # @return [String] The next player
  def next_player
    self.current_player == 'blue' ? 'red' : 'blue'
  end

  # setNextPlayer sets the next player
  #
  # @return [String] The new player
  def set_next_player
    self.current_player = next_player
  end

  # returns the piece at the coordinates
  def board_position(coords)
    raise(ArgumentError, "Coords (#{col}, #{row}) are out of bounds.") unless coords_valid?(coords)
    self.board[coords[0]][coords[1]]
  end

  # checks that the given coordinates are within the valid range
  def coords_valid?(coords)
    col, row = coords
    (0...NUM_COLUMNS).cover?(col) && (0...NUM_ROWS).cover?(row)
  end

  # MakeMove takes a column and player and updates the board to reflect the
  # given move. Also will update :current_player and :status
  #
  # @param column [Integer]
  # @param player [String] either 'red' or 'blue'
  def make_move(column, player)
    raise ArgumentError, 'Player is invalid' unless player == current_player
    raise ArgumentError, 'Column is out of bounds' unless 0 <= column && column < NUM_COLUMNS - 1

    # Find the lowest empty row in this column
    row = (0..NUM_ROWS-1).find{|row| self.board_position([column, row]) == nil}
    raise ArgumentError, 'Column is full' if row == nil

    # update board, current_player and status
    self.board[column][row] = player
    self.set_next_player
    self.check_for_winner
  end

  # Checks if there is a winner and returns the player if it exists
  #
  # @return [String] 'red', 'blue', 'tie', or 'in_progress'
  def check_for_winner
    time_it("check all coordinates") {self.status = check_all_for_winner}
    time_it("check the min set of coordinates") {check_min_set_for_winner}
    # self.status = check_all_for_winner
    # check_min_set_for_winner
    self.status
  end

  # Determine how long it takes to complete a task
  def time_it(descr)
    start = Time.now.to_f
    yield
    finish = Time.now.to_f
    puts "It took #{(finish - start).round(5)} seconds to #{descr}"
  end


  #############################################################################

  private


  # This section finds a winner in (almost) the most efficient way I could think of.
  # Worst-case scenario, the coordinates in DIAG_CANDIDATES will, redundantly, get
  # looked up three times.  Avoiding that requires uglier code.
  # 
  # Note: when run against the test data, this approach is generally slower than checking all coordinates

  # The positions from which a horizontal/vertical/diagonal win might begin 
  HORIZ_CANDIDATES = (0...NUM_COLUMNS-3).flat_map{|col| (0...NUM_ROWS).map{|row| [col,row]}}
  VERT_CANDIDATES = (0...NUM_COLUMNS).flat_map{|col| (0...NUM_ROWS-3).map{|row| [col,row]}}
  DIAG_CANDIDATES = (0...NUM_COLUMNS-3).flat_map{|col| (0...NUM_ROWS-3).map{|row| [col,row]}}

  # check the minimum set of coordinates for a winner
  def check_min_set_for_winner
    winning_coords =  HORIZ_CANDIDATES.find{|coords| horizontal_win? coords} ||
      VERT_CANDIDATES.find{|coords| vertical_win? coords} ||
      DIAG_CANDIDATES.find{|coords| diagonal_win? coords}

    if winning_coords != nil
      return board_position(winning_coords)
    else
      return 'in_progress'
    end
  end

  # check for a horizontal win
  def horizontal_win?(coords)
    color = self.board_position(coords)
    (1..3).all?{|dist| color != nil && board_position(horizontal(coords, dist)) == color}
  end

  # check for a vertical win
  def vertical_win?(coords)
    color = self.board_position(coords)
    (1..3).all?{|dist| color != nil && board_position(vertical(coords, dist)) == color}
  end

  # check for a diagonal win
  def diagonal_win?(coords)
    color = self.board_position(coords)
    (1..3).all?{|dist| color != nil && board_position(diagonal(coords, dist)) == color}
  end

  def tie?
    # TODO
  end



  # This section of code checks every single coordinate for a winner.
  # I modified the methods slightly 
  # 

  # check each board position for a winning streak
  #
  # @return [Array] the winning coordinates, if any
  def check_all_for_winner
    each_board_position do |coords|
      return board_position(coords) if win_in_any_direction?(coords)
    end
    return 'in_progress'
  end

  # Checks for a win - horizontally, vertically and diagonally - from the current set of coordinates
  # 
  # @param coords [Array] the coordinates to check, e.g. [0,0]
  def win_in_any_direction?(coords)
    color = board_position(coords)
    [horizontal_proc, vertical_proc, diagonal_proc].any? do |func|
      (1..3).all?{|dist| color != nil && board_position(func.call(coords, dist)) == color}
    end
  end

  # Alternative way of writing the win_in_any_direction method.
  # This method works with the out-of-the-box mixin methods.
  # The other win_in_any_direction has less code repetition but makes it awkward to 
  # call the horiz/diag/vert methods from normal code because they're procs.
  def win_in_any_direction2?(coords)
    color = board_position(coords)
    (1..3).all?{|dist| color != nil && board_position(horizontal(coords, dist)) == color} ||
      (1..3).all?{|dist| color != nil && board_position(vertical(coords, dist)) == color} ||
      (1..3).all?{|dist| color != nil && board_position(diagonal(coords, dist)) == color}
  end

end
