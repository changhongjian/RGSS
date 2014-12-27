
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#    设置技能、物品的使用目标。
#--------------------------------------------------------------------------
#
# 使用方法：
#   在技能/道具的备注栏写下类似于这样的备注。
#   备注后，无视技能效果范围中“单体”或“全体”的设置。
#   无人符合条件时，保持原来的使用目标。
#
#   例1：存活队员中 hp 最小者。
#   <target>
#     select: alive?
#     min_by: hp_rate
#   </target>
#
#   例2：所有 hp 大于 50 的队员
#   <target>
#     select: hp > 50
#   </target>
#
#   例3：随机指定两个存活队员中 hp 小于一半的人。
#   <target>
#     select: alive? && hp_rate < 0.5
#     sample(2)
#   </target>
#
#--------------------------------------------------------------------------

# 解析备注栏中的备注
class << Taroxd::TargetExt = Object.new

  RE_OUTER = /<target>(.*?)<\/target>/mi # 整体设置
  RE_INNER = /(\S+) *(?:: *(.+))?/       # 每一行的设置

  def parse_note(note)
    note =~ RE_OUTER ? parse_settings($1.scan(RE_INNER)) : false
  end

  # lambda do |members|
  #   members.select { |battler| battler.instance_eval {
  #     alive? && hp_rate < 0.5 } }.sample(2)
  # end
  def parse_settings(settings)
    eval %(
      lambda do |members|
        members#{extract_settings(settings)}
      end
    )
  end

  def extract_settings(settings)
    settings.map { |method, body|
      if body
        ".#{method} { |battler| battler.instance_eval { #{body} } }"
      else
        ".#{method}"
      end
    }.join
  end

end

class RPG::UsableItem < RPG::BaseItem

  # 缓存生成的 lambda
  def get_target
    return @get_target unless @get_target.nil?
    @get_target = Taroxd::TargetExt.parse_note(@note)
  end

  # 是否需要选择目标
  def_unless :need_selection?, :get_target

end

class Game_Action

  # 返回计算结果或原来的值
  def targets_for_eval(unit, old)
    get_target = item.get_target
    return old.call unless get_target
    targets = get_target.call(unit.members)
    return old.call unless targets
    targets = Array(targets)
    targets.empty? ? old.call : targets
  end

  # 目标为敌人
  def_chain :targets_for_opponents do |old|
    targets_for_eval(opponents_unit, old)
  end

  # 目标为队友
  def_chain :targets_for_friends do |old|
    targets_for_eval(friends_unit, old)
  end

end