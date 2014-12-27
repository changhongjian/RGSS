
#----------------------------------------------------------------------------
# ● require Taroxd基础设置
#    简化重复事件的设置
#----------------------------------------------------------------------------
#    使用方法：
#      在事件名称上备注 <render event_id> 
#        那么这个事件会完全被该地图中的事件 event_id 代替。
#      在事件名称上备注 <render event_id map_id>
#        那么这个事件会完全被地图 map_id 中的事件 event_id 代替。
#----------------------------------------------------------------------------

Taroxd::RenderEvent = true

class RPG::Event

  # 重定义：获取事件页
  def pages
    @rendered_pages ||= rendered_pages
  end

  private

  # 获取要替换的事件
  def rendered_pages
    return @pages unless @name =~ /<render\s+(\d+)(\s+\d+)?>/i
    rendered_map($2).events[$1.to_i].pages
  end

  # 获取地图
  def rendered_map(match)
    if match
      load_data sprintf("Data/Map%03d.rvdata2", match.to_i)
    else
      $game_map.data_object
    end
  end
end
