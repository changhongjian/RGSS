
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    使用方法：技能备注<alive and dead>
#--------------------------------------------------------------------------

Taroxd::AliveAndDead = true

RPG::UsableItem.note_bool :alive_and_dead?

class Game_Unit
  #--------------------------------------------------------------------------
  # ● 决定顺带目标
  #--------------------------------------------------------------------------
  def alive_and_dead_smooth_target(index)
    members[index] ? members[index] : members[0]
  end
end

class Game_Action
  #--------------------------------------------------------------------------
  # ● 目标为队友
  #--------------------------------------------------------------------------
  def_chain :targets_for_friends do |old|
    if item.alive_and_dead?
      if item.for_one?
        [friends_unit.alive_and_dead_smooth_target(@target_index)]
      else
        friends_unit.members
      end
    else
      old.call
    end
  end
end

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 技能／物品的应用测试
  #--------------------------------------------------------------------------
  def_chain :item_test do |old, user, item|
    if item.alive_and_dead?
      return true if $game_party.in_battle
      return true if item.for_opponent?
      return true if item.damage.recover? && item.damage.to_hp? && hp < mhp
      return true if item.damage.recover? && item.damage.to_mp? && mp < mmp
      return true if item_has_any_valid_effects?(user, item)
      return false
    else
      old.(user, item)
    end
  end
end
