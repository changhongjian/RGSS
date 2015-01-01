
#==============================================================================
# ★ require Taroxd基础设置
#    给值槽增加动态的滚动效果
#==============================================================================

class Taroxd::Transition
  # value: 当前值。changing: 当前是否正在变化
  attr_reader :value, :changing

  # block 应返回变化的目标
  def initialize(duration, &block)
    @duration = duration
    @block = block
    @value = @target = block.call
    @d = 0
  end

  def update
    @target = @block.call
    @changing = @value != @target
    update_transition if @changing
  end

  private

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

  Transition = Taroxd::Transition

  # 值槽滚动所需的帧数
  def gauge_roll_frame; 30; end

  # 每隔多少帧刷新一次值槽
  def gauge_roll_interval; 1; end

  # 值槽滚动所需的次数
  def gauge_roll_times; gauge_roll_frame / gauge_roll_interval; end

  def initialize(*)
    @gauge_transitions = Hash.new do |hash, actor|
      hash[actor] = {
        hp: Transition.new(gauge_roll_times) { actor.hp },
        mp: Transition.new(gauge_roll_times) { actor.mp },
        tp: Transition.new(gauge_roll_times) { actor.tp },
      }
    end
    @gauge_transitions.compare_by_identity
    @gauge_roll_count = 0
    super
  end

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

  # 滚动所有值槽。可在子类重定义。
  def roll_all_gauge
    refresh
  end

  def draw_actor_hp(actor, x, y, width = 124)
    hp = @gauge_transitions[actor][:hp].value
    rate = hp.fdiv(actor.mhp)
    draw_gauge(x, y, width, rate, hp_gauge_color1, hp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::hp_a)
    draw_current_and_max_values(x, y, width, hp.to_i, actor.mhp,
      hp_color(actor), normal_color)
  end

  def draw_actor_mp(actor, x, y, width = 124)
    mp = @gauge_transitions[actor][:mp].value
    rate = mp.fdiv(actor.mmp)
    draw_gauge(x, y, width, rate, mp_gauge_color1, mp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::mp_a)
    draw_current_and_max_values(x, y, width, mp.to_i, actor.mmp,
      mp_color(actor), normal_color)
  end

  def draw_actor_tp(actor, x, y, width = 124)
    tp = @gauge_transitions[actor][:tp].value
    rate = tp.fdiv(actor.max_tp)
    draw_gauge(x, y, width, rate, tp_gauge_color1, tp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::tp_a)
    change_color(tp_color(actor))
    draw_text(x + width - 42, y, 42, line_height, tp.to_i, 2)
  end

end

class Window_BattleStatus
  include Taroxd::RollGauge
end

class Window_MenuStatus < Window_Selectable

  include Taroxd::RollGauge

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
