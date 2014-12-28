
#----------------------------------------------------------------------------
# ● require 事件转译器
#----------------------------------------------------------------------------

class Game_Interpreter

  debug = true  # 调试模式

  if $TEST && debug

    def run
      wait_for_message
      code = Taroxd::Translator.translate(@list)
      puts code
      eval code, binding
      Fiber.yield
      @fiber = nil
    rescue Object => e
      p e
      rgss_stop
    end
    
  else
    
    def run
      wait_for_message
      eval Taroxd::Translator.translate(@list)
      Fiber.yield
      @fiber = nil
    end
  end
end
