
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    使用方法：在装备/技能/角色/职业上备注 <attackskill x> / <guardskill x>
#--------------------------------------------------------------------------

module Taroxd::AttackSkill
  COMPATIBILITY = false
end

class RPG::BaseItem
  note_i :attack_skill, false
  note_i :guard_skill,  false
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● 获取普通攻击的技能 ID
  #--------------------------------------------------------------------------
  def_chain :attack_skill_id do |old|
    note_objects {|item| return item.attack_skill if item.attack_skill }
    old.call
  end
  #--------------------------------------------------------------------------
  # ● 获取防御的技能 ID
  #--------------------------------------------------------------------------
  def_chain :guard_skill_id do |old|
    note_objects {|item| return item.guard_skill if item.guard_skill }
    old.call
  end
end

unless Taroxd::AttackSkill::COMPATIBILITY

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # ● 普通攻击无需选择目标的情况
  #--------------------------------------------------------------------------
  def_chain :command_attack do |old|
    skill = $data_skills[BattleManager.actor.attack_skill_id]
    if !skill.need_selection?
      BattleManager.actor.input.set_attack
      next_command
    elsif skill.for_opponent?
      old.call
    else
      BattleManager.actor.input.set_attack
      select_actor_selection
    end
  end
  #--------------------------------------------------------------------------
  # ● 防御需要选择目标的情况
  #--------------------------------------------------------------------------
  def_chain :command_guard do |old|
    skill = $data_skills[BattleManager.actor.guard_skill_id]
    if skill.need_selection?
      BattleManager.actor.input.set_guard
      skill.for_opponent? ? select_enemy_selection : select_actor_selection
    else
      old.call
    end
  end
end

class Window_ActorCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● 更改攻击指令名称
  #--------------------------------------------------------------------------
  def add_attack_command
    name = $data_skills[@actor.attack_skill_id].name
    add_command(name, :attack, @actor.attack_usable?)
  end
  #--------------------------------------------------------------------------
  # ● 更改防御指令名称
  #--------------------------------------------------------------------------
  def add_guard_command
    name = $data_skills[@actor.guard_skill_id].name
    add_command(name, :guard, @actor.guard_usable?)
  end
end

end # unless Taroxd::AttackSkill::COMPATIBILITY