
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
      # 不添加 binding 参数。建议与【脚本快捷方式】( Taroxd::Eval ) 配合使用。
      eval code
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
