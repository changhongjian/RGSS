
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    使用方法：在可以设置“特性”的地方备注 <drain r>。
#              其中 r 为吸血的比例。
#--------------------------------------------------------------------------

Taroxd::Drain = true

RPG::BaseItem.note_f :drain

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 处理伤害
  #--------------------------------------------------------------------------
  def_after :execute_damage do |user|
    user.hp += (@result.hp_damage * user.feature_objects.sum(&:drain)).to_i
  end
end