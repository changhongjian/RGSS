
#--------------------------------------------------------------------------
# ● 反转 Shift 的功能
#--------------------------------------------------------------------------

module Taroxd
  ShiftReverse = true
end

class Game_Player < Game_Character

  def dash?
    !@move_route_forcing && !$game_map.disable_dash? &&
      !vehicle && !Input.press?(:A)
  end

end