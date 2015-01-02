
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    偷懒用的事件脚本。
#--------------------------------------------------------------------------
#
#    添加了以下方法：
#
#    Game_Interpreter
#      this_event: 获取本事件。如果事件不在当前地图上，返回 nil。
#      add_battlelog(text): 追加战斗信息。
#      self_switch
#      self_switch(event_id)
#      self_switch(event_id, map_id):
#        返回对应事件的 SelfSwitch 对象。
#
#    Game_Switches/Game_Variables/Game_SelfSwitches
#       clear / reset: 清空数据
#
#    Game_CharacterBase
#       zoom_x, zoom_y, angle, mirror 属性: 控制对应 Sprite 的属性。
#       force_pattern(pattern):
#         将行走图强制更改为对应的 pattern。
#         pattern 从左到右分别为 0, 1, 2。
#         使用此功能时，建议勾选固定朝向，并且取消步行动画。
#
#    Game_Player
#       waiting 属性：设为真值时，禁止玩家移动
#       wait_for { block }:
#         执行 block 期间玩家不能移动。
#         请注意不要在 block 中 return。
#         如果一定需要的话，记得将 waiting 属性设为伪值，使玩家重新可以移动。
#
#    Game_Party
#       +(gold), -(gold): 增加/减少金钱，并返回 self。
#       <<(actor), <<(actor_id): 加入指定队员，并返回 self。
#
#--------------------------------------------------------------------------

module Taroxd::EventCommandExt

  # 定义了清除数据的方法
  module ClearData

    Game_Switches.send     :include, self
    Game_Variables.send    :include, self
    Game_SelfSwitches.send :include, self

    def clear
      @data.clear
      on_change
      self
    end

    alias reset clear

  end

  # 代表独立开关的对象
  class SelfSwitch

    def initialize(map_id, event_id)
      @map_id = map_id
      @event_id = event_id
    end

    def [](letter)
      $game_self_switches[[@map_id, @event_id, letter]]
    end

    def []=(letter, value)
      $game_self_switches[[@map_id, @event_id, letter]] = value
    end

    def a; self['A']; end
    def b; self['B']; end
    def c; self['C']; end
    def d; self['D']; end

    def a=(v); self['A'] = v; end
    def b=(v); self['B'] = v; end
    def c=(v); self['C'] = v; end
    def d=(v); self['D'] = v; end
  end

end


class Game_Interpreter
  
  include Taroxd::EventCommandExt

  def this_event
    $game_map.events[@event_id] if same_map?
  end

  def add_battlelog(text)
    if SceneManager.scene_is?(Scene_Battle)
      SceneManager.scene.add_battlelog(text)
    end
  end

  def self_switch(event_id = @event_id, map_id = @map_id)
    SelfSwitch.new(map_id, event_id)
  end

end

class Game_CharacterBase

  attr_accessor :zoom_x, :zoom_y, :angle, :mirror

  def force_pattern(pattern)
    @original_pattern = @pattern = pattern
  end

end


class Game_Player < Game_Character

  attr_accessor :waiting

  def_unless :movable?, :waiting

  # 为了在事件解释器的 fiber 中使用，因此不用 ensure 语句。
  def wait_for
    @waiting = true
    yield
    @waiting = false
  end

end

class Game_Party < Game_Unit

  def +(gold)
    gain_gold(gold)
    self
  end

  def -(gold)
    lose_gold(gold)
    self
  end

  def <<(actor)
    add_actor(actor.id)
    self
  end

end

class Sprite_Character < Sprite_Base

  # 更新对应属性
  def_after :update_other do
    self.zoom_x = @character.zoom_x if @character.zoom_x
    self.zoom_y = @character.zoom_y if @character.zoom_y
    self.angle  = @character.angle  if @character.angle
    self.mirror = @character.mirror unless @character.mirror.nil?
  end

end

class Scene_Battle < Scene_Base

  def add_battlelog(text)
    @log_window.add_text(text)
  end

end
