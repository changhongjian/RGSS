
#--------------------------------------------------------------------------
# ● require Taroxd基础设置，全键盘控制
#    快速存档读档 
#--------------------------------------------------------------------------

module Taroxd::QuickSL
  KEY_SAVE = Keyboard::S                   # 存档键
  KEY_LOAD = Keyboard::L                   # 读档键
  #--------------------------------------------------------------------------
  # ● 存档位置
  #--------------------------------------------------------------------------
  def quick_save_index
    0
  end
  #--------------------------------------------------------------------------
  # ● 快速存档
  #--------------------------------------------------------------------------
  def quick_save
    if DataManager.save_game(quick_save_index)
      on_quick_save_success
    else
      Sound.play_buzzer
    end
  end
  #--------------------------------------------------------------------------
  # ● 快速读档
  #--------------------------------------------------------------------------
  def quick_load
    if DataManager.load_game(quick_save_index)
      on_quick_load_success
    else
      Sound.play_buzzer
    end
  end
  #--------------------------------------------------------------------------
  # ● 快速存档成功时的处理
  #--------------------------------------------------------------------------
  def on_quick_save_success
    Sound.play_save
  end
  #--------------------------------------------------------------------------
  # ● 快速读档成功时的处理
  #--------------------------------------------------------------------------
  def on_quick_load_success
    Sound.play_load
    SceneManager.scene.fadeout_all
    $game_system.on_after_load
    SceneManager.goto(Scene_Map)
  end
  #--------------------------------------------------------------------------
  # ● 监听快速存档键的按下
  #--------------------------------------------------------------------------
  def update_call_quick_save
    quick_save if !$game_system.save_disabled && Keyboard.trigger?(KEY_SAVE)
  end
  #--------------------------------------------------------------------------
  # ● 监听快速读档键的按下
  #--------------------------------------------------------------------------
  def update_call_quick_load
    quick_load if Keyboard.trigger?(KEY_LOAD)
  end
  #--------------------------------------------------------------------------
  # ● 监听快速存/读档键的按下
  #--------------------------------------------------------------------------
  def update_call_quickSL
    update_call_quick_save
    update_call_quick_load
  end
end

class Scene_Map < Scene_Base
  include Taroxd::QuickSL
  #--------------------------------------------------------------------------
  # ● 场景更新
  #--------------------------------------------------------------------------
  def_after(:update_scene) { update_call_quickSL unless scene_changing? }
end

class Scene_Title < Scene_Base
  include Taroxd::QuickSL
  #--------------------------------------------------------------------------
  # ● 场景更新
  #--------------------------------------------------------------------------
  def_after(:update) { update_call_quick_load unless scene_changing? }
end

class Game_Interpreter
  include Taroxd::QuickSL
end