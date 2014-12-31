
#----------------------------------------------------------------------------
# ● require 事件转译器
#----------------------------------------------------------------------------

class Taroxd::Translator

  # 是否需要与旧存档兼容。不是新工程的话填 true。
  SAVEDATA_COMPATIBLE = false

  # 调试模式，开启时会将转译的脚本输出到控制台
  DEBUG_MODE = true

  @cache = {}

  def self.cache
    @cache
  end

end

class Game_Interpreter

  Translator = Taroxd::Translator

  def rb_code
    Translator.translate(@list, @map_id, @event_id)
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

  def run
    wait_for_message
    instance_eval(&compile_code)
    Fiber.yield
    @fiber = nil
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

    def compile_code
      proc = Translator.cache[[@list, @map_id, @event_id]]
      return proc if proc
      code = rb_code
      puts code
      Translator.cache[[@list, @map_id, @event_id]] =
        eval(code, translator_binding)
    rescue StandardError, SyntaxError => e
      p e
      puts e.backtrace
      rgss_stop
    end

  else

    def compile_code
      Translator.cache[[@list, @map_id, @event_id]] ||=
        eval(rb_code, translator_binding)
    end

  end # if $TEST && Translator::DEBUG_MODE
end

# 切换地图时，清除事件页转译代码的缓存

class Game_Map

  alias setup_without_translator setup

  def setup(map_id)
    setup_without_translator(map_id)
    Taroxd::Translator.cache.clear
  end

end
