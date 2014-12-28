
#============================================================================
#  〇 require Taroxd基础设置
#     使用方法：在角色处备注 <learn x by y>，表示当持有道具 y 时习得技能 x
#============================================================================

Taroxd::LearnSkillByItem = /<learn\s*(\d+)\s*by\s*(\d+)>/i

class RPG::Actor < RPG::BaseItem
  #--------------------------------------------------------------------------
  # ● 获取由 [技能id, 物品] 构成的数组
  #--------------------------------------------------------------------------
  def learn_skill_by_item
    @learn_skill_by_item ||=
    @note.scan(Taroxd::LearnSkillByItem).map {|(x, y)|
      [x.to_i, $data_items[y.to_i]] }
  end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● 获取添加的技能
  #--------------------------------------------------------------------------
  def_with :added_skills do |old|
    actor.learn_skill_by_item.each {|(skill_id, item)|
      old.push(skill_id) if $game_party.has_item?(item) }
    old
  end
end