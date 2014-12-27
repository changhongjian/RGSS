
#============================================================================
#  〇 require Taroxd基础设置
#     使用方法：技能备注 <itemcost x>，x 为消耗的道具 id
#============================================================================

Taroxd::ItemCost = true

class RPG::Skill < RPG::UsableItem
  note_any :item_cost, false, /\s*(\d+)/, '$data_items[$1.to_i]'
end

class Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 判定是否足够扣除技能的使用消耗
  #--------------------------------------------------------------------------
  def_and :skill_cost_payable? do |skill|
    !skill.item_cost || $game_party.has_item?(skill.item_cost)
  end
  #--------------------------------------------------------------------------
  # ● 扣除技能的使用消耗
  #--------------------------------------------------------------------------
  def_after :pay_skill_cost do |skill|
    $game_party.lose_item(skill.item_cost, 1) if skill.item_cost
  end
end

class Window_SkillList < Window_Selectable
  #--------------------------------------------------------------------------
  # ● 绘制技能的使用消耗
  #--------------------------------------------------------------------------
  def draw_skill_cost(rect, skill)
    contents.font.size -= 6
    change_color(tp_cost_color, enable?(skill))
    draw_skill_cost_icon(rect, skill, @actor.skill_tp_cost(skill), 189)
    change_color(mp_cost_color, enable?(skill))
    draw_skill_cost_icon(rect, skill, @actor.skill_mp_cost(skill), 188)
    item = skill.item_cost
    draw_skill_cost_icon(rect, skill, 1, item.icon_index) if item
    contents.font.size += 6
  end
  #--------------------------------------------------------------------------
  # ● 绘制技能使用消耗的图标
  #--------------------------------------------------------------------------
  def draw_skill_cost_icon(rect, skill, cost, icon_index)
    return if cost == 0
    x = rect.x + rect.width - 24
    draw_icon(icon_index, x, rect.y, enable?(skill))
    draw_text(x, rect.y + 8, 24, 16, cost, 2) unless cost == 1
    rect.width -= 24
  end
end
