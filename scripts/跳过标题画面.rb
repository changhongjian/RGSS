
#----------------------------------------------------------------------------
# ● 测试游戏时跳过标题画面
#----------------------------------------------------------------------------

module Taroxd
  SkipTitle = true
end

def SceneManager.first_scene_class
  return Scene_Battle if $BTEST
  DataManager.setup_new_game
  $game_map.autoplay
  Scene_Map
end if $TEST