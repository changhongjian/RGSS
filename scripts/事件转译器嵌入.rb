
#----------------------------------------------------------------------------
# ● require 事件转译器
#----------------------------------------------------------------------------

class Taroxd::Translator

  # 是否需要与旧存档兼容。不是新工程的话填 true。
  SAVEDATA_COMPATIBLE = false

  # 调试模式，开启时会将转译的脚本输出到控制台
  DEBUG_MODE = true

  @cache = {}

  def self.rb_code(list, map_id, event_id)
    @cache[list] ||= translate(list, map_id, event_id)
  end

  def self.clear_cache
    @cache.clear
  end
end

class Game_Interpreter

  Translator = Taroxd::Translator

  def rb_code
    Translator.rb_code(@list, @map_id, @event_id)
  end

  # 定义一些局部变量，便于事件脚本的使用
  def translator_binding
    v = variables  = $game_variables
    s = switches   = $game_switches
    n = a = actors = $game_actors
    p = party      = $game_party
    g = gold       = $game_party.gold
    e = troop      = $game_troop
    m = map        = $game_map
    player         = $game_player
    binding
  end

  unless Translator::SAVEDATA_COMPATIBLE
    def marshal_dump
      [@map_id, @event_id, @list]
    end

    def marshal_load(obj)
      @map_id, @event_id, @list = obj
      create_fiber
    end
  end

  if $TEST && Translator::DEBUG_MODE

    def run
      wait_for_message
      puts rb_code
      eval rb_code, translator_binding
      Fiber.yield
      @fiber = nil
    rescue StandardError, SyntaxError => e
      p e
      puts e.backtrace
      rgss_stop
    end

  else

    def run
      wait_for_message
      eval rb_code, translator_binding
      Fiber.yield
      @fiber = nil
    end

  end # if $TEST && Translator::DEBUG_MODE
end

# 切换地图时，清除事件页转译代码的缓存

class Game_Map

  alias setup_without_translator setup

  def setup(map_id)
    setup_without_translator(map_id)
    Taroxd::Translator.clear_cache
  end

end
