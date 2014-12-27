
#----------------------------------------------------------------------------
# ● require Taroxd基础设置
#----------------------------------------------------------------------------

module Taroxd::Eval
  #--------------------------------------------------------------------------
  # ● 脚本中的简称列表
  #--------------------------------------------------------------------------
  SCRIPT_ABBR_LIST = {
    'V' => '$game_variables',
    'S' => '$game_switches',
    'N' => '$game_actors',
    'A' => '$game_actors',
    'P' => '$game_party',
    'G' => '$game_party.gold',
    'E' => '$game_troop'
  }
  #--------------------------------------------------------------------------
  # ● 处理脚本用的正则表达式
  #--------------------------------------------------------------------------
  SCRIPT_ABBR_RE = 
    /(?<!::|['"\.])\b(?:#{SCRIPT_ABBR_LIST.keys.join('|')})\b(?! *[(@$\w'"])/
  #--------------------------------------------------------------------------
  module_function
  #--------------------------------------------------------------------------
  # ● 对脚本的处理
  #--------------------------------------------------------------------------
  def process_script(script)
    script.gsub(SCRIPT_ABBR_RE, SCRIPT_ABBR_LIST)
  end
  #--------------------------------------------------------------------------
  # ● 执行脚本
  #--------------------------------------------------------------------------
  def eval(script, *args)
    v = $game_variables
    s = $game_switches
    n = $game_actors
    a = $game_actors
    p = $game_party
    g = $game_party.gold
    e = $game_troop
    script = process_script(script)
    if args.empty?
      instance_eval(script, __FILE__, __LINE__)
    else
      Kernel.eval(script, *args)
    end
  end
  #--------------------------------------------------------------------------
  # ● 混入模块
  #--------------------------------------------------------------------------
  Game_Character.send   :include, self
  Game_Interpreter.send :include, self
end
  
class RPG::UsableItem::Damage
  #--------------------------------------------------------------------------
  # ● 根据参数执行计算公式
  #--------------------------------------------------------------------------
  def eval(a, b, v)
    value = Taroxd::Eval.eval(@formula, b.formula_binding(a, b, v))
    value > 0 ? value * sign : 0
  end
end

class Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 执行计算公式的环境
  #--------------------------------------------------------------------------
  def formula_binding(a, b, v)
    s = $game_switches
    n = $game_actors
    p = $game_party
    g = $game_party.gold
    e = $game_troop
    binding
  end
end

class Window_Base < Window
  #--------------------------------------------------------------------------
  # ● 对 #{} 的处理
  #--------------------------------------------------------------------------
  process_expression = Proc.new do |old|
    old.gsub(/\e?#(?<brace>\{([^{}]|\g<brace>)*\})/) do |code|
      next code if code.slice!(0) == "\e"
      Taroxd::Eval.eval code[1..-2]
    end
  end
  def_with :convert_escape_characters, process_expression
end
