
#--------------------------------------------------------------------------
# ● require Astar寻路
#--------------------------------------------------------------------------

Taroxd::EventAStar = true

class Game_Character
  #--------------------------------------------------------------------------
  # ● 寻路
  #--------------------------------------------------------------------------
  def find_path_toward(x, y)
    return @find_path if @find_path_xy == [x, y, @x, @y]
    @find_path = Taroxd::AStar.path(self, x, y)
    @find_path_xy = x, y, @x, @y
    @find_path
  end
  #--------------------------------------------------------------------------
  # ● 接近人物
  #--------------------------------------------------------------------------
  alias move_toward_character_directly move_toward_character
  def move_toward_character(character)
    dir = find_path_toward(character.x, character.y).shift
    return move_toward_character_directly(character) unless dir
    move_straight(dir)
    @find_path_xy[2, 2] = @x, @y if @move_succeed
  end
end

class Game_Event
  #--------------------------------------------------------------------------
  # ● 移动类型：接近
  #--------------------------------------------------------------------------
  def move_type_toward_player
    move_toward_player
  end
end