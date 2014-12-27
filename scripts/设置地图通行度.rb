
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    设置地图通行度
#--------------------------------------------------------------------------
#
#  使用方法1：在“设置区域通行度”处填入一定可以通行的区域和一定不能通行的区域。
#
#    例：PASSABLE_REGIONS = [2, 5, 8..11]
#        表明区域 2, 5, 8, 9, 10, 11 可以通行，无论上面是什么图块。
#
#  使用方法2：** require 显示地图通行度 **
#
#    测试模式下，把 EDIT_MODE 设为 true，
#    然后在地图上按下确定键即可改变当前位置的通行度。
#
#    △表示不改变，○表示可以通行，×表示不可通行。颜色表示最终的通行度。
#
#    设置时，不要忘了测试模式下按住 Ctrl 键可以穿透。
#
#    需要清空设置的话，删除设置文件（见 FILE 常量）即可。
#
#    需要重置一张地图的设置的话，可以调用如下脚本：
#      Taroxd::Passage.clear(map_id)
#    其中 map_id 为地图 ID。若要清除当前地图的通行度，map_id 可以不填。
#    注意，清除后，通行度的显示并不会立即改变。重新打开游戏即可看到效果。
#
#--------------------------------------------------------------------------

module Taroxd::Passage

  # 地图通行度信息会保存到这个文件。建议每次编辑前备份该文件。
  FILE = 'Data/MapPassage.rvdata2'

  # 是否打开编辑模式。需要前置脚本“显示地图通行度”才可打开。
  EDIT_MODE = true

  # 编辑方式（可整合鼠标脚本）
  EDIT_TRIGGER = -> { Input.trigger?(:C) }
  EDIT_POINT   = -> { [$game_player.x, $game_player.y] }

  # 设置区域通行度。可以使用区间。
  PASSABLE_REGIONS   = []    # 可以通行的区域
  IMPASSABLE_REGIONS = []    # 不可通行的区域

  # 读取通行度的哈希表。以地图ID为键，以通行度的二维 Table 为值。
  PASSAGE_DATA = File.exist?(FILE) ? load_data(FILE) : {}

  # 常量，不建议改动
  DEFAULT    = 0
  PASSABLE   = 1
  IMPASSABLE = 2
  TEXTS = ['△', '○', '×']
  SIZE = TEXTS.size

  module_function
  #--------------------------------------------------------------------------
  # ● 判断该点是否一定可以通行
  #--------------------------------------------------------------------------
  def passable?(x, y)
    return true if data[x, y] == PASSABLE
    rid = $game_map.region_id(x, y)
    PASSABLE_REGIONS.any? { |e| e === rid }
  end
  #--------------------------------------------------------------------------
  # ● 判断该点是否一定不可以通行
  #--------------------------------------------------------------------------
  def impassable?(x, y)
    return true if data[x, y] == IMPASSABLE
    rid = $game_map.region_id(x, y)
    IMPASSABLE_REGIONS.any? { |e| e === rid }
  end
  #--------------------------------------------------------------------------
  # ● 获取当前地图的数据
  #--------------------------------------------------------------------------
  def data
    table = PASSAGE_DATA[map_id] ||= Table.new(width, height)
    if table.xsize < width || table.ysize < height
      update_table(table)
    else
      table
    end
  end
  #--------------------------------------------------------------------------
  # ● 如果表格不够大，那么重新建立表格
  #--------------------------------------------------------------------------
  def update_table(table)
    PASSAGE_DATA[map_id] = new_table = Table.new(width, height)
    table.xsize.times do |x|
      table.ysize.times do |y|
        new_table[x, y] = table[x, y]
      end
    end
    new_table
  end
  #--------------------------------------------------------------------------
  # ● 更新，每帧调用一次
  #--------------------------------------------------------------------------
  def update
    return unless EDIT_TRIGGER.call
    x, y = EDIT_POINT.call
    data[x, y] = (data[x, y] + 1) % SIZE
    save
  end
  #--------------------------------------------------------------------------
  # ● 清除设置
  #--------------------------------------------------------------------------
  def clear(map_id = $game_map.map_id)
    PASSAGE_DATA.delete(map_id)
    save
  end
  #--------------------------------------------------------------------------
  # ● 将所有数据保存到文件
  #--------------------------------------------------------------------------
  def save
    save_data(PASSAGE_DATA, FILE)
  end
  #--------------------------------------------------------------------------
  # ● 获取当前地图 id
  #--------------------------------------------------------------------------
  def map_id
    $game_map.map_id
  end
  #--------------------------------------------------------------------------
  # ● 获取当前地图宽度
  #--------------------------------------------------------------------------
  def width
    $game_map.width
  end
  #--------------------------------------------------------------------------
  # ● 获取当前地图高度
  #--------------------------------------------------------------------------
  def height
    $game_map.height
  end
end

class Game_Map
  #--------------------------------------------------------------------------
  # ● 是否可以通行
  #--------------------------------------------------------------------------
  def_chain :passable? do |old, x, y, d|
    return true if Taroxd::Passage.passable?(x, y)
    return false if Taroxd::Passage.impassable?(x, y)
    old.call(x, y, d)
  end
end

if $TEST && Taroxd::Passage::EDIT_MODE

# 使地图通行度的显示默认可见
Taroxd::ShowPassage.const_set :VISIBLE, true

# 每帧调用一次 Taroxd::Passage.update
Game_Player.send :def_after, :update, Taroxd::Passage.method(:update)

class Plane_Passage < Plane

  TEXT_RECT = Rect.new(0, 0, 32, 32)

  include Taroxd::Passage

  #--------------------------------------------------------------------------
  # ● 获取通行度文字的位图缓存
  #--------------------------------------------------------------------------
  def text_bitmaps
    @text_bitmap_cache ||= TEXTS.map do |text|
      bitmap = Bitmap.new(TEXT_RECT.width, TEXT_RECT.height)
      bitmap.draw_text(TEXT_RECT, text, 1)
      bitmap
    end
  end
  #--------------------------------------------------------------------------
  # ● 释放通行度文字的位图缓存
  #--------------------------------------------------------------------------
  def dispose_text_bitmaps
    @text_bitmaps_cache.each(&:dispose) if @text_bitmaps
  end
  #--------------------------------------------------------------------------
  # ● 描绘通行度设置
  #--------------------------------------------------------------------------
  def_after :draw_point do |x, y|
    bitmap.blt(x * 32, y * 32, text_bitmaps[data[x, y]], TEXT_RECT)
  end
  #--------------------------------------------------------------------------
  # ● 更新通行度的变化
  #--------------------------------------------------------------------------
  def update_passage_change
    return unless EDIT_TRIGGER.call
    x, y = EDIT_POINT.call
    bitmap.clear_rect(x * 32, y * 32, 32, 32)
    draw_point(x, y)
  end
  #--------------------------------------------------------------------------
  # ● 导入
  #--------------------------------------------------------------------------
  def_after :update, :update_passage_change
  def_before :dispose, :dispose_text_bitmaps
end

end # if $TEST && Taroxd::Passage::EDIT_MODE