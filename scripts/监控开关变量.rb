
#----------------------------------------------------------------------------
# ● 监控开关变量
#----------------------------------------------------------------------------

Taroxd::Monitor.config do
  #--------------------------------------------------------------------------
  # ● 设置区域
  #--------------------------------------------------------------------------
end

BEGIN {

module Taroxd end

class << Taroxd::Monitor = Object.new
  LIST = {}
  alias config instance_eval
  #--------------------------------------------------------------------------
  # ● 获取变量的值
  #--------------------------------------------------------------------------
  def operate(id, value)
    proc = LIST[id]
    proc ? proc.(value) : value
  end
  #--------------------------------------------------------------------------
  # ● 增加开关监控（不可存档）
  #--------------------------------------------------------------------------
  def switch(id, &proc)
    LIST[-id] = proc
  end
  #--------------------------------------------------------------------------
  # ● 增加变量监控（不可存档）
  #--------------------------------------------------------------------------
  def variable(id, &proc)
    LIST[id] = proc
  end
  #--------------------------------------------------------------------------
  # ● 是否正在监控
  #--------------------------------------------------------------------------
  def include?(id)
    LIST[id]
  end
end

} # BEGIN

class Game_Switches
  #--------------------------------------------------------------------------
  # ● 获取开关
  #--------------------------------------------------------------------------
  alias no_monitor_value []
  def [](id)
    Taroxd::Monitor.operate(-id, no_monitor_value(id))
  end
end

class Game_Variables
  #--------------------------------------------------------------------------
  # ● 获取变量
  #--------------------------------------------------------------------------
  alias no_monitor_value []
  def [](id)
    Taroxd::Monitor.operate(id, no_monitor_value(id))
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 操作变量
  #--------------------------------------------------------------------------
  def operate_variable(id, type, value)
    $game_variables[id] =
    case type
    when 0  # 代入
      value
    when 1  # 加法
      $game_variables.no_monitor_value(id) + value
    when 2  # 减法
      $game_variables.no_monitor_value(id) - value
    when 3  # 乘法
      $game_variables.no_monitor_value(id) * value
    when 4  # 除法
      value.zero? ? 0 : $game_variables.no_monitor_value(id) / value
    when 5  # 取余
      value.zero? ? 0 : $game_variables.no_monitor_value(id) % value
    end
  end
end

class Window_DebugRight < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 更新开关模式
  #--------------------------------------------------------------------------
  def update_switch_mode
    return unless Input.trigger?(:C)
    id = current_id
    $game_switches[id] = !$game_switches.no_monitor_value(id)
    Sound.play_ok
    redraw_current_item
  end
  #--------------------------------------------------------------------------
  # ● 更新变量模式
  #--------------------------------------------------------------------------
  def update_variable_mode
    id = current_id
    value = $game_variables.no_monitor_value(id)
    return unless value.is_a?(Numeric)
    value += 1 if Input.repeat?(:RIGHT)
    value -= 1 if Input.repeat?(:LEFT)
    value += 10 if Input.repeat?(:R)
    value -= 10 if Input.repeat?(:L)
    if $game_variables.no_monitor_value(current_id) != value
      $game_variables[id] = value
      Sound.play_cursor
      redraw_current_item
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制
  #--------------------------------------------------------------------------
  def draw_item(index)
    data_id = @top_id + index
    id_text = sprintf("%04d:", data_id)
    id_width = text_size(id_text).width
    if @mode == :switch
      name = $data_system.switches[data_id]
      status = $game_switches.no_monitor_value(data_id) ? "[ON]" : "[OFF]"
      if Taroxd::Monitor.include?(-data_id)
        status.concat($game_switches[data_id] ? ' ->  [ON]' : ' -> [OFF]')
      end
    else
      name = $data_system.variables[data_id]
      status = $game_variables.no_monitor_value(data_id).to_s
      if Taroxd::Monitor.include?(data_id)
        status << ' -> ' << $game_variables[data_id].to_s
      end
    end
    name = "" unless name
    rect = item_rect_for_text(index)
    change_color(normal_color)
    draw_text(rect, id_text)
    rect.x += id_width
    rect.width -= id_width + 60
    draw_text(rect, name)
    rect.width += 60
    draw_text(rect, status, 2)
  end
end