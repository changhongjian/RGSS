
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    使用方法：备注<hrg x>，表示每回合回复 x 点 HP。
#              备注<mrg x>，表示每回合回复 x 点 MP。
#              备注<trg x>，表示每回合回复 x 点 TP。
#              x 可以为负数
#--------------------------------------------------------------------------

Taroxd::ConstRG = true

%w(h m t).each do |type|
  name = "#{type}rg"
  RPG::BaseItem.note_f name
  Game_BattlerBase.class_eval %{
    def_with :#{name} do |old|
      max = m#{type}p
      max == 0 ? old : feature_objects.sum(old) {|obj| obj.#{name} / max }
    end
  }
end