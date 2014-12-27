
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    同名的敌人不附加字母后缀
#--------------------------------------------------------------------------

Taroxd::EnemyNoSuffix = false

class Game_Troop < Game_Unit
  def_after(:make_unique_names) { each {|enemy| enemy.letter = '' } }
end