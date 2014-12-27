
#============================================================================
#  〇 require Taroxd基础设置，动态值槽
#     战斗中敌人显示血条
#     如不想显示，可在敌人处备注 <hide hp>
#     如要对敌人单独调整坐标，可在敌人处备注 <hp pos adjust x y>
#     如要对敌人调整血槽宽度，可在敌人处备注 <hp width x>
#============================================================================

Taroxd::EnemyHP = true

class RPG::Enemy < RPG::BaseItem
  note_any :hp_pos_adjust,[0,0],/\s+(-?\d+)\s+(-?\d+)/,'[$1.to_i, $2.to_i]'
  note_i :hp_width, 80
  note_bool :hide_hp?
end

class Sprite_EnemyHP < Sprite
  include Taroxd::RollGauge
  #--------------------------------------------------------------------------
  # ● 常量设定
  #--------------------------------------------------------------------------
  HP_COLOR1 = Color.new(223, 127, 63)
  HP_COLOR2 = Color.new(239, 191, 63)
  BACK_COLOR = Color.new(31, 31, 63)
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport, enemy)
    super(viewport)
    @gauge_transitions = Taroxd::Transition.new(gauge_roll_times) do 
      enemy.hp.fdiv(enemy.mhp)
    end
    enemy_data = enemy.enemy
    unless enemy_data.hide_hp?
      self.bitmap = Bitmap.new(enemy_data.hp_width, 6)
      dx, dy = enemy_data.hp_pos_adjust
      self.x = enemy.screen_x + dx
      self.y = enemy.screen_y + dy
      self.z = enemy.screen_z
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    @gauge_transitions.update
    refresh if @gauge_transitions.changing
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    bitmap.dispose if bitmap
    super
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh
    bitmap.clear if bitmap
    rate = @gauge_transitions.value
    return if rate == 0
    fill_w = (bitmap.width * rate).to_i
    bitmap.fill_rect(fill_w, 0, bitmap.width - fill_w, 6, BACK_COLOR)
    bitmap.gradient_fill_rect(0, 0, fill_w, 6, HP_COLOR1, HP_COLOR2)
  end
end

class Spriteset_Battle
  #--------------------------------------------------------------------------
  # ● 创建敌人血条
  #--------------------------------------------------------------------------
  def_after :create_enemies do
    @enemy_hp_sprites = $game_troop.members.reverse.collect do |enemy|
      Sprite_EnemyHP.new(@viewport1, enemy)
    end
  end
  #--------------------------------------------------------------------------
  # ● 更新敌人血条
  #--------------------------------------------------------------------------
  def_after(:update_enemies) { @enemy_hp_sprites.each(&:update) }
  #--------------------------------------------------------------------------
  # ● 释放敌人血条
  #--------------------------------------------------------------------------
  def_after(:dispose_enemies) { @enemy_hp_sprites.each(&:dispose) }
end