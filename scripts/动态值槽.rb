
#==============================================================================
# ★ require Taroxd基础设置
#    给值槽增加动态的滚动效果
#==============================================================================

class Taroxd::Transition
  attr_reader :value, :changing
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(duration, &block)
    @duration = duration
    @block = block
    @value = @target = block.call
    @d = 0
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @target = @block.call
    @changing = @value != @target
    update_transition if @changing
  end
  #--------------------------------------------------------------------------
  # ● 更新变化
  #--------------------------------------------------------------------------
  def update_transition
    @d = @duration if @d.zero?
    @d -= 1
    @value = 
    if @d.zero?
      @target
    else
      (@value * @d + @target).fdiv(@d + 1)
    end
  end
end

module Taroxd::RollGauge
  #--------------------------------------------------------------------------
  # ● 值槽滚动所需的帧数
  #--------------------------------------------------------------------------
  def gauge_roll_frame; 30; end
  #--------------------------------------------------------------------------
  # ● 每隔多少帧刷新一次值槽
  #--------------------------------------------------------------------------
  def gauge_roll_interval; 1; end
  #--------------------------------------------------------------------------
  # ● 值槽滚动所需的次数
  #--------------------------------------------------------------------------
  def gauge_roll_times; gauge_roll_frame / gauge_roll_interval; end
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(*)
    @gauge_transitions = Hash.new do |hash, actor|
      hash[actor] = {
        hp: Taroxd::Transition.new(gauge_roll_times) { actor.hp },
        mp: Taroxd::Transition.new(gauge_roll_times) { actor.mp },
        tp: Taroxd::Transition.new(gauge_roll_times) { actor.tp },
      }
    end
    @gauge_transitions.compare_by_identity
    @gauge_roll_count = 0
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    super
    if (@gauge_roll_count += 1) >= gauge_roll_interval
      need_roll = false
      @gauge_transitions.each_value do |hash|
        hash.each_value do |t|
          t.update
          need_roll = true if t.changing
        end
      end
      roll_all_gauge if need_roll
      @gauge_roll_count = 0
    end
  end
  #--------------------------------------------------------------------------
  # ● 绘制角色 HP
  #--------------------------------------------------------------------------
  def draw_actor_hp(actor, x, y, width = 124)
    hp = @gauge_transitions[actor][:hp].value
    rate = hp.fdiv(actor.mhp)
    draw_gauge(x, y, width, rate, hp_gauge_color1, hp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::hp_a)
    draw_current_and_max_values(x, y, width, hp.to_i, actor.mhp,
      hp_color(actor), normal_color)
  end
  #--------------------------------------------------------------------------
  # ● 绘制角色 MP
  #--------------------------------------------------------------------------
  def draw_actor_mp(actor, x, y, width = 124)
    mp = @gauge_transitions[actor][:mp].value
    rate = mp.fdiv(actor.mmp)
    draw_gauge(x, y, width, rate, mp_gauge_color1, mp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::mp_a)
    draw_current_and_max_values(x, y, width, mp.to_i, actor.mmp,
      mp_color(actor), normal_color)
  end
  #--------------------------------------------------------------------------
  # ● 绘制角色 TP
  #--------------------------------------------------------------------------
  def draw_actor_tp(actor, x, y, width = 124)
    tp = @gauge_transitions[actor][:tp].value
    rate = tp.fdiv(actor.max_tp)
    draw_gauge(x, y, width, rate, tp_gauge_color1, tp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::tp_a)
    change_color(tp_color(actor))
    draw_text(x + width - 42, y, 42, line_height, tp.to_i, 2)
  end
  #--------------------------------------------------------------------------
  # ● 滚动所有值槽
  #--------------------------------------------------------------------------
  def roll_all_gauge
    refresh
  end
end

class Window_BattleStatus
  include Taroxd::RollGauge
end

class Window_MenuStatus < Window_Selectable
  include Taroxd::RollGauge
  #--------------------------------------------------------------------------
  # ● 滚动所有值槽
  #--------------------------------------------------------------------------
  def roll_all_gauge
    item_max.times do |i|
      actor = $game_party.members[i]
      rect = item_rect(i)
      rect.x += 108
      rect.y += line_height / 2
      contents.clear_rect(rect)
      draw_actor_simple_status(actor, rect.x, rect.y)
    end
  end
end
