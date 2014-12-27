
#----------------------------------------------------------------------------
# ● 允许按 CTRL 跳过对话
#----------------------------------------------------------------------------

module Taroxd
  CtrlFastForward = true
end

class Window_Message < Window_Base
  #--------------------------------------------------------------------------
  # ● 处理输入等待
  #--------------------------------------------------------------------------
  def input_pause
    return if Input.press?(:CTRL)
    self.pause = true
    wait(10)
    Fiber.yield until [:B, :C, :CTRL].any?(&Input.method(:trigger?))
    Input.update
    self.pause = false
  end
end
