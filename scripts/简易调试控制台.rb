
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    简易调试控制台
#--------------------------------------------------------------------------

if $TEST

class << Taroxd::Console = Object.new
  
  KEY = :F5
  
  help_sep = '-' * 79
  
  HELP = [
    help_sep,
    '在控制台中可以执行任意脚本。下面是一些快捷方式。',
    help_sep,
    'exit: 退出控制台并返回游戏。',
    'help: 显示这段帮助。',
    'recover: 完全恢复。',
    'save(index = 0): 存档到指定位置',
    'load(index = 0, exit = true): 从指定位置读档。exit 为真时，返回游戏。',
    'kill(hp = 1): 将敌方全体的 HP 降到 hp。仅战斗中可用。',
    'suicide(hp = 1): 将己方全体的 HP 降到 hp。',
    help_sep
  ]
  
  EXIT_IDENTIFIER = :exit

  #--------------------------------------------------------------------------
  # ● 获取窗口句柄
  #--------------------------------------------------------------------------
  console = Win32API.new('Kernel32', 'GetConsoleWindow', '', 'L').call
  game = Win32API.new('user32', 'GetActiveWindow', '', 'L').call
  hwnd = game
  set_window_pos = Win32API.new('user32', 'SetWindowPos', 'LLLLLLL', 'L')
  #--------------------------------------------------------------------------
  # ● 切换窗口
  #--------------------------------------------------------------------------
  define_method :switch_window do
    hwnd = hwnd == game ? console : game
    set_window_pos.call(hwnd, 0, 0, 0, 0, 0, 3)
  end
  #--------------------------------------------------------------------------
  # ● 如果按下按键，则进入控制台
  #--------------------------------------------------------------------------
  def update
    start if Input.trigger?(KEY)
  end
  #--------------------------------------------------------------------------
  # ● 进入控制台
  #--------------------------------------------------------------------------
  def start
    switch_window
    @binding = get_binding
    begin
      while (line = gets)
        next unless line[/\S/]
        result = eval(line, @binding)
        break switch_window if result.equal?(EXIT_IDENTIFIER)
        print '=> '
        p result
      end
    rescue => e
      p e
      retry
    end
  end
  #--------------------------------------------------------------------------
  # ● 获取 binding
  #--------------------------------------------------------------------------
  def get_binding
    v = $game_variables
    s = $game_switches
    n = $game_actors
    a = $game_actors
    p = $game_party
    g = $game_party.gold
    e = $game_troop
    scene = SceneManager.scene
    binding
  end
  #--------------------------------------------------------------------------
  # ● 退出控制台
  #--------------------------------------------------------------------------
  def exit
    EXIT_IDENTIFIER
  end
  #--------------------------------------------------------------------------
  # ● 输出可用的方法
  #--------------------------------------------------------------------------
  def help
    puts HELP
  end
  #--------------------------------------------------------------------------
  # ● 完全恢复
  #--------------------------------------------------------------------------
  def recover
    $game_party.recover_all
  end
  #--------------------------------------------------------------------------
  # ● 存档
  #--------------------------------------------------------------------------
  def save(index = 0)
    Sound.play_save
    DataManager.save_game_without_rescue(index)
  end
  #--------------------------------------------------------------------------
  # ● 读档
  #--------------------------------------------------------------------------
  def load(index = 0, to_exit = true)
    DataManager.load_game_without_rescue(index)
    Sound.play_load
    $game_system.on_after_load
    SceneManager.goto(Scene_Map)
    to_exit ? exit : true
  end
  #--------------------------------------------------------------------------
  # ● 将敌方全体的 HP 减少到指定值
  #--------------------------------------------------------------------------
  def kill(hp = 1)
    return unless $game_party.in_battle
    $game_troop.each { |a| a.hp = hp }
  end
  #--------------------------------------------------------------------------
  # ● 将己方全体的 HP 减少到指定值
  #--------------------------------------------------------------------------
  def suicide(hp = 1)
    $game_party.each { |a| a.hp = hp }
  end
end

Scene_Base.send :def_after, :update, Taroxd::Console.method(:update)

end # if $TEST