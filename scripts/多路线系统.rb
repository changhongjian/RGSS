
#----------------------------------------------------------------------------
# ● require Taroxd基础设置，全局变量存档
#----------------------------------------------------------------------------
#
#  一条路线，包括玩家位置，队伍成员，持有物品和**地图事件**执行状态等。
#  游戏中的变量和开关是所有路线共有的。
#  该脚本可以进行路线的切换。
#  游戏开始时，路线 id 为 0。
#
#  进入空路线时，队伍无成员，不持有任何物品。玩家的位置不变。
#  建议通过 set_route(id, false) 来初始化一条空路线。
#
#  在事件脚本中输入：
#    set_route(id)：
#      切换到第 id 号路线，有淡入淡出效果，并中断事件的处理。
#    set_route(id, false)：
#      切换到第 id 号路线，但没有淡入淡出效果，不中断事件的处理。
#    merge_route(id)：将第 id 号路线并入当前路线，并清除第 id 号路线。
#    clear_route(id)：清除第 id 号路线。
#    current_route.id：获取当前路线的 id。
#
#----------------------------------------------------------------------------

module Taroxd::Route
  #--------------------------------------------------------------------------
  # ● 设置路线
  #--------------------------------------------------------------------------
  def set_route
    current_route[route_type] = make_route
    restore_route(current_route[route_type])
  end
  #--------------------------------------------------------------------------
  module_function
  #--------------------------------------------------------------------------
  # ● 清除路线
  #--------------------------------------------------------------------------
  def clear_route(id = nil)
    current_route.clear(id)
  end
  #--------------------------------------------------------------------------
  # ● 获取当前的路线
  #--------------------------------------------------------------------------
  def current_route
    Taroxd::Global[:route] ||= Routes.new
  end

  class Routes
    attr_reader :id
    #------------------------------------------------------------------------
    # ● 初始化
    #------------------------------------------------------------------------
    def initialize
      @id = @last_id = 0
      @routes = []
    end
    #------------------------------------------------------------------------
    # ● 切换路线
    #------------------------------------------------------------------------
    def id=(id)
      @last_id = @id
      clear(@last_id)
      @id = id
    end
    #------------------------------------------------------------------------
    # ● 清除路线
    #------------------------------------------------------------------------
    def clear(id = nil)
      if id
        @routes[id] = nil
      else
        @routes.clear
      end
    end
    #------------------------------------------------------------------------
    # ● 获取路线
    #------------------------------------------------------------------------
    def route(id)
      @routes[id] ||= {}
    end
    #------------------------------------------------------------------------
    # ● 保存上次路线数据
    #------------------------------------------------------------------------
    def []=(type, data)
      route(@last_id)[type] = data
    end
    #------------------------------------------------------------------------
    # ● 获取当前路线数据
    #------------------------------------------------------------------------
    def [](type)
      route(@id)[type]
    end
  end
end

class Game_Interpreter
  include Taroxd::Route
  #--------------------------------------------------------------------------
  # ● 设置路线
  #    suspend：自动淡入淡出，并保存当前事件状态
  #--------------------------------------------------------------------------
  def set_route(id, suspend = true)
    return if $game_party.in_battle || current_route.id == id
    command_221 if suspend            # 淡出画面
    current_route.id = id
    $game_party.set_route
    $game_player.set_route
    $game_player.refresh
    $game_map.need_refresh = true
    Fiber.yield while $game_player.transfer?
    return unless suspend
    command_222                       # 淡入画面
    $game_map.set_route
    Fiber.yield
  end
  #--------------------------------------------------------------------------
  # ● 合并路线
  #--------------------------------------------------------------------------
  def merge_route(id)
    return if current_route.id == id
    $game_party.merge_route(id)
    $game_player.refresh
    $game_map.need_refresh = true
    clear_route(id)
  end
end

class Game_Map
  include Taroxd::Route
  #--------------------------------------------------------------------------
  # ● 路线类型
  #--------------------------------------------------------------------------
  def route_type
    :interpreter
  end
  #--------------------------------------------------------------------------
  # ● 路线数据
  #--------------------------------------------------------------------------
  def make_route
    interpreter = @interpreter
    @interpreter = Game_Interpreter.new
    interpreter
  end
  #--------------------------------------------------------------------------
  # ● 恢复路线数据
  #--------------------------------------------------------------------------
  def restore_route(data)
    @interpreter = data if data
  end
end

class Game_Player
  include Taroxd::Route
  #--------------------------------------------------------------------------
  # ● 路线类型
  #--------------------------------------------------------------------------
  def route_type
    :position
  end
  #--------------------------------------------------------------------------
  # ● 路线数据
  #--------------------------------------------------------------------------
  def make_route
    [$game_map.map_id, x, y, direction]
  end
  #--------------------------------------------------------------------------
  # ● 恢复路线数据
  #--------------------------------------------------------------------------
  def restore_route(data)
    return unless data
    reserve_transfer(*data)
    refresh
  end
end

class Game_Party < Game_Unit
  include Taroxd::Route
  #--------------------------------------------------------------------------
  # ● 路线类型
  #--------------------------------------------------------------------------
  def route_type
    :party
  end
  #--------------------------------------------------------------------------
  # ● 路线数据
  #--------------------------------------------------------------------------
  def make_route
    [@gold, @actors, @items, @weapons, @armors]
  end
  #--------------------------------------------------------------------------
  # ● 恢复路线数据
  #--------------------------------------------------------------------------
  def restore_route(data)
    if data
      @gold, @actors, @items, @weapons, @armors = data
    else
      @gold = 0
      @actors = []
      init_all_items
    end
  end
  #--------------------------------------------------------------------------
  # ● 合并路线
  #--------------------------------------------------------------------------
  def merge_route(id)
    data = current_route.route(id)[route_type]
    return unless data
    gold, actors, items, weapons, armors = data
    gain_gold(gold)
    @actors |= actors
    merge_item @items,   items,   $data_items
    merge_item @weapons, weapons, $data_weapons
    merge_item @armors,  armors,  $data_armors
  end
  #--------------------------------------------------------------------------
  # ● 合并物品
  #--------------------------------------------------------------------------
  def merge_item(to, from, database)
    to.merge!(from) do |id, v1, v2|
      [v1 + v2, max_item_number(database[id])].min
    end
  end
end
