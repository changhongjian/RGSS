
#--------------------------------------------------------------------------
# ● 自动显示得失物品提示
#--------------------------------------------------------------------------

module Taroxd end

module Taroxd::GainMessage
  #--------------------------------------------------------------------------
  # ● 常数设置
  #--------------------------------------------------------------------------
  SWITCH = 0      # 开关打开时功能开启。可以填入 0 表示始终打开。
  GAIN   = '获得'
  LOSE   = '失去'
  ITEM_FORMAT  = '%s了 %s * %d'   # 获得/失去了 某物品 * N
  GOLD_FORMAT  = '%s了 %d %s'     # 获得/失去了 N 金钱单位
  BACKGROUND   = 1                # 窗口背景（0/1/2）
  POSITION     = 1                # 显示位置（0/1/2）
  GAIN_GOLD_SE = 'Shop'           # 获得金钱音效（不需要的话可以直接删去该行）
  LOSE_GOLD_SE = 'Blow2'          # 失去金钱音效（不需要的话可以直接删去该行）
  GAIN_ITEM_SE = 'Item1'          # 获得物品音效（不需要的话可以直接删去该行）
  LOSE_ITEM_SE = LOSE_GOLD_SE     # 失去物品音效（不需要的话可以直接删去该行）
  #--------------------------------------------------------------------------
  module_function
  #--------------------------------------------------------------------------
  # ● 功能是否启用
  #--------------------------------------------------------------------------
  def enabled?
    SWITCH.zero? || $game_switches[SWITCH]
  end
  #--------------------------------------------------------------------------
  # ● 准备
  #--------------------------------------------------------------------------
  def prepare(value, item)
    @item = item
    @value = value
    $game_message.background = BACKGROUND
    $game_message.position = POSITION
    play_se
  end
  #--------------------------------------------------------------------------
  # ● 获取提示的消息
  #--------------------------------------------------------------------------
  def message
    prefix = @value > 0 ? GAIN : LOSE
    if @item
      sprintf(ITEM_FORMAT, prefix, @item.name, @value.abs)
    else
      sprintf(GOLD_FORMAT, prefix, @value.abs, Vocab.currency_unit)
    end
  end
  #--------------------------------------------------------------------------
  # ● 播放音效
  #--------------------------------------------------------------------------
  def play_se
    const = :"#{@value > 0 ? 'GAIN' : 'LOSE'}_#{@item ? 'ITEM' : 'GOLD'}_SE"
    se = const_defined?(const) && const_get(const)
    Audio.se_play('Audio/SE/' + se) if se
  end
end

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● 获取道具总数（包括装备）
  #--------------------------------------------------------------------------
  def item_number_with_equip(item)
    members.inject(item_number(item)) {|a, e| a + e.equips.count(item) }
  end
end

class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● 不显示提示窗口的事件指令
  #--------------------------------------------------------------------------
  alias gain_gold_without_message   command_125
  alias gain_item_without_message   command_126
  alias gain_weapon_without_message command_127
  alias gain_armor_without_message  command_128
  #--------------------------------------------------------------------------
  # ● 显示提示窗口
  #--------------------------------------------------------------------------
  def show_gain_message(value, item = nil)
    return if value.zero?
    Taroxd::GainMessage.prepare value, item
    wait_for_message
    $game_message.add Taroxd::GainMessage.message
    wait_for_message
  end
  #--------------------------------------------------------------------------
  # ● 增减持有金钱
  #--------------------------------------------------------------------------
  def command_125
    return gain_gold_without_message unless Taroxd::GainMessage.enabled?
    last_gold = $game_party.gold
    gain_gold_without_message
    show_gain_message($game_party.gold - last_gold)
  end
  #--------------------------------------------------------------------------
  # ● 增减物品
  #--------------------------------------------------------------------------
  def command_126
    return gain_item_without_message unless Taroxd::GainMessage.enabled?
    item = $data_items[@params[0]]
    last_num = $game_party.item_number(item)
    gain_item_without_message
    show_gain_message($game_party.item_number(item) - last_num, item)
  end
  #--------------------------------------------------------------------------
  # ● 增减武器
  #--------------------------------------------------------------------------
  def command_127
    return gain_weapon_without_message unless Taroxd::GainMessage.enabled?
    item = $data_weapons[@params[0]]
    last_num = $game_party.item_number_with_equip(item)
    gain_weapon_without_message
    value = $game_party.item_number_with_equip(item) - last_num
    show_gain_message(value, item)
  end
  #--------------------------------------------------------------------------
  # ● 增减护甲
  #--------------------------------------------------------------------------
  def command_128
    return gain_armor_without_message unless Taroxd::GainMessage.enabled?
    item = $data_armors[@params[0]]
    last_num = $game_party.item_number_with_equip(item)
    gain_armor_without_message
    value = $game_party.item_number_with_equip(item) - last_num
    show_gain_message(value, item)
  end
end