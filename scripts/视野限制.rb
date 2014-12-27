
#==============================================================================
# ● require Taroxd基础设置
#    使用方法：在地图备注<sight x>，则该地图限制视野。x 为可见范围
#    在角色、职业、装备、状态上备注<sight x>，则可以设置 x 的视野补正
#==============================================================================

Taroxd::Sight = true

RPG::Map.note_i :sight, false
RPG::BaseItem.note_i :sight

class Game_Map
  #--------------------------------------------------------------------------
  # ● 视野限制值
  #--------------------------------------------------------------------------
  def shadow_sight
    @map.sight
  end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● 视野补正值
  #--------------------------------------------------------------------------
  def sight_power
    note_objects.sum(&:sight)
  end
end

class Sprite_SightShadow < Sprite_Base
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(viewport = nil)
    super(viewport)
    self.z = 160
    self.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    update
  end
  #--------------------------------------------------------------------------
  # ● 阴影的位图
  #--------------------------------------------------------------------------
  def shadow_bitmap
    Cache.system('sight_shadow')
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    bitmap.dispose
    shadow_bitmap.dispose
    super
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update
    self.visible = $game_map.shadow_sight
    return unless visible
    w = $game_party.alive_members.sum($game_map.shadow_sight, &:sight_power)
    x = $game_player.screen_x - w / 2
    y = $game_player.screen_y - w / 2 - 16
    return if @last_position == [w, x, y]
    @last_position = w, x, y
    width, height = Graphics.width, Graphics.height
    rect = Rect.new(x, y, w, w)
    black = Color.new(0, 0, 0)
    bitmap.clear
    bitmap.stretch_blt(rect, shadow_bitmap, shadow_bitmap.rect)
    bitmap.fill_rect(0, 0, width, y, black)
    bitmap.fill_rect(0, y + w, width, height - y - w, black)
    bitmap.fill_rect(0, y, x, w, black)
    bitmap.fill_rect(x + w, y, width - x - w, w, black)
  end
end

Spriteset_Map.use_sprite(Sprite_SightShadow) { @viewport2 }
