
#============================================================================
# 〇 清除战斗日志
#============================================================================

module Taroxd
  class ClearBattleLog < BasicObject
    ::Object.const_set :Window_BattleLog, self
    def initialize(*) end
    def method_missing(*) end
  end
end

