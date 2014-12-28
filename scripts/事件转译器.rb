
#----------------------------------------------------------------------------
# ● 事件转译器
#----------------------------------------------------------------------------

class << Taroxd::Translator = Object.new

  # 将 command 直接代理给 Game_Interpreter#command_xxx
  # 不需要获取 @params 时，可令 set_params 为 nil
  def self.delegate_command code,
    set_params = '@params = ObjectSpace._id2ref(#{@params.__id__})'
    # def command_233
    #   "@params = ObjectSpace._id2ref(#{@params.__id__})
    #   command_233"
    # end
    module_eval %{
      def command_#{code}
        "#{set_params}
        command_#{code}"
      end
    }
  end

  # 翻译事件指令代码，并放入 lambda 中，以便于 return
  def translate(list)
    "-> {
      #{translate_code(list)}
    }.call"
  end

  # 将事件指令翻译成代码。list：事件指令列表
  def translate_code(list)
    @list = list
    @index = -1
    ret = ''
    ret << translate_command << "\n" while next_command!
    ret
  end

  private

  def translate_command(command = @command)
    @params = command.parameters
    sym = :"command_#{@command.code}"
    respond_to?(sym, true) && send(sym) || ''
  end

  # 分支。
  # 方法开始时，@index 应位于分支开始之前的位置
  # 方法结束后，@index 将位于分支结束之后的位置
  def translate_branch(indent)
    ret = ''
    until next_command!.indent == indent
      ret << translate_command << "\n"
    end
    ret
  end

  def current_command
    @list[@index]
  end

  def current_params
    current_command.parameters
  end

  def current_indent
    current_command.indent
  end

  def current_code
    current_command.code
  end

  def next_command
    @list[@index + 1]
  end

  def next_command!
    @index += 1
    @command = @list[@index]
  end

  def next_params!
    next_command!.parameters
  end

  def next_code
    next_command.code
  end

  # 返回脚本中的表达形式。obj 可以为字符串或数组。
  # 字符串中的 <%= code %> 会被替换为 #{code}
  def escape(obj)
    ret = obj.inspect
    ret.gsub!(/<%=(.+)%>/m, '#{\1}') if obj.kind_of?(String)
    ret
  end

  # escape 之后去除双引号
  def escape_script(code)
    escape(code)[1..-2]
  end

  def setup_choices(params)
    ret = ''
    params[0].each do |s|
      ret << "$game_message.choices.push(#{escape s})\n"
    end
    ret << "$game_message.choice_cancel_type = #{params[1]}
    $game_message.choice_proc = Proc.new do |n|
      case n
    "
    next_command!
    until current_code == 404 # 选项结束
      # 取消的场合为 4，否则为对应选项
      n = current_code == 403 ? 4 : current_params[0]
      ret << "when #{n}\n" <<
        translate_branch(current_indent) << "\n"
    end
    ret << "end\nend\n" # end case; end Proc.new
  end

  # 显示文字
  def command_101
    ret = "
    wait_for_message
    $game_message.face_name = #{escape @params[0]}
    $game_message.face_index = #{@params[1]}
    $game_message.background = #{@params[2]}
    $game_message.position = #{@params[3]}
    "
    while next_code == 401 # 文字数据
      data = escape next_params![0]
      ret << "$game_message.add(#{data})\n"
    end
    case next_code
    when 102  # 显示选项
      ret << setup_choices(next_params!)
    when 103  # 数值输入的处理
      ret << "setup_num_input(#{escape next_params!})\n"
    when 104  # 物品选择的处理
      ret << "setup_item_choice(#{escape next_params!})\n"
    end
    ret << "wait_for_message\n"
  end

  # 显示选项
  def command_102
    "
    wait_for_message
    #{setup_choices(@params)}
    Fiber.yield while $game_message.choice?
    "
  end

  # 显示滚动文字
  def command_105
    ret = "
    Fiber.yield while $game_message.visible
    $game_message.scroll_mode = true
    $game_message.scroll_speed = #{@params[0]}
    $game_message.scroll_no_fast = #{@params[1]}
    "
    while next_code == 405
      ret << "$game_message.add(#{escape next_params![0]})\n"
    end
    ret << "wait_for_message\n"
  end

  # 添加注释
  def command_108
    ret = "@comments = #{escape @params}\n"
    while next_code == 408
      ret << "@comments.push(#{escape next_params![0]})"
    end
  end

  # 分支条件
  def command_111
    result =
    case @params[0]
    when 0  # 开关
      "$game_switches[#{@params[1]}] == (#{@params[2]} == 0)"
    when 1  # 变量
      value1 = "$game_variables[#{@params[1]}]"
      value2 = 
        if @params[2] == 0
          @params[3]
        else
          "$game_variables[#{@params[3]}]"
        end
      case @params[4]
      when 0  # 等于
        "#{value1} == #{value2}"
      when 1  # 以上
        "#{value1} >= #{value2}"
      when 2  # 以下
        "#{value1} <= #{value2}"
      when 3  # 大于
        "#{value1} > #{value2}"
      when 4  # 小于
        "#{value1} < #{value2}" 
      when 5  # 不等于
        "#{value1} != #{value2}"
      end
    when 2  # 独立开关
      if @event_id > 0
        "(#{@params[2] != 0}) ^ "\
        "$game_self_switches[[@map_id, @event_id, #{@params[1]}]]"
      else
        'false'
      end
    when 3  # 计时器
      mark = @params[2] == 0 ? '>=' : '<='
      "$game_timer.working? && $game_timer.sec #{mark} #{@params[1]}"
    when 4  # 角色
      "begin 
        actor = $game_actors[#{@params[1]}]
        if actor
      " <<
        case @params[2]
        when 0  # 在队伍时
          '$game_party.members.include?(actor)'
        when 1  # 名字
          "actor.name == #{escape @params[3]}"
        when 2  # 职业
          "actor.class_id == #{@params[3]}"
        when 3  # 技能
          "actor.skill_learn?($data_skills[#{@params[3]}])"
        when 4  # 武器
          "actor.weapons.include?($data_weapons[#{@params[3]}])"
        when 5  # 护甲
          "actor.armors.include?($data_armors[#{@params[3]}])"
        when 6  # 状态
          "actor.state?(#{@params[3]})"
        end << "\nend\nend" # if actor; begin
    when 5  # 敌人
      "begin 
        enemy = $game_troop.members[#{@params[1]}]
        if enemy
      " << 
        case @params[2]
        when 0  # 出现
          'enemy.alive?'
        when 1  # 状态
          "enemy.state?(#{@params[3]})"
        end << "\nend\nend" # if enemy; begin
    when 6  # 事件
      "begin
        character = get_character(#{@params[1]})
        if character
          character.direction == #{@params[2]}
        end
      end"
    when 7  # 金钱
      case @params[2]
      when 0  # 以上
        "$game_party.gold >= #{@params[1]}"
      when 1  # 以下
        "$game_party.gold <= #{@params[1]}"
      when 2  # 低于
        "$game_party.gold < #{@params[1]}"
      end
    when 8   # 物品
      "$game_party.has_item?($data_items[#{@params[1]}])"
    when 9   # 武器
      "$game_party.has_item?($data_weapons[#{@params[1]}], #{@params[2]})"
    when 10  # 护甲
      "$game_party.has_item?($data_armors[#{@params[1]}], #{@params[2]})"
    when 11  # 按下按钮
      "Input.press?(#{escape @params[1]})"
    when 12  # 脚本
      "begin
        #{escape_script(@params[1])}
      end"
    when 13  # 载具
      "$game_player.vehicle == $game_map.vehicles[#{@params[1]}]"
    end
    "if #{result}\n"
  end

  # 否则
  def command_411
    'else'
  end

  # 分支结束
  def command_412
    'end'
  end

  # 循环
  def command_112
    'while true'
  end

  # 重复
  def command_413
    'end'
  end

  # 跳出循环
  def command_113
    'break'
  end

  # 中止事件处理
  def command_115
    'return'
  end

  # 公共事件
  def command_117
    common_event = $data_common_events[@params[0]]
    translate_code(common_event.list)
  end

  # 添加标签
  def command_118
    raise NotImplementedError
  end

  # 转至标签
  alias_method :command_119, :command_118

  # 开关操作
  def command_121
    "#{@params[0]}.upto(#{@params[1]}) do |i|
      $game_switches[i] = #{@params[2] == 0}
    end"
  end

  # 变量操作
  def command_122
    value =
    case @params[3]  # 操作方式
    when 0  # 常量
      @params[4]
    when 1  # 变量
      "$game_variables[#{@params[4]}]"
    when 2  # 随机数
      "#{@params[4]} + rand(#{@params[5] - @params[4] + 1})"
    when 3  # 游戏数据
      "game_data_operand(#{@params[4]}, #{@params[5]}, #{@params[6]})"
    when 4  # 脚本
      escape_script @params[4]
    end
    "#{@params[0]}.upto(#{@params[1]}) do |i|
      operate_variable(i, #{@params[2]}, #{value})
    end"
  end

  # 独立开关操作
  def command_123
    "if @event_id > 0
      key = [@map_id, @event_id, #{escape @params[0]}]
      $game_self_switches[key] = #{@params[1] == 0}
    end"
  end

  # 计时器操作
  def command_124
    if @params[0] == 0  # 开始
      "$game_timer.start(#{@params[1] * Graphics.frame_rate})"
    else                # 停止
      '$game_timer.stop'
    end
  end
  # 队伍管理
  def command_129
    ret = ''
    actor = $game_actors[@params[0]]
    if actor
      if @params[1] == 0    # 入队
        if @params[2] == 1  # 初始化
          ret << "$game_actors[#{@params[0]}].setup(#{@params[0]})\n"
        end
        ret << "$game_party.add_actor(#{@params[0]})"
      else                  # 离队
        ret << "$game_party.remove_actor(#{@params[0]})"
      end
    end
  end

  # 设置禁用存档
  def command_134
    "$game_system.menu_disabled = #{@params[0] == 0}"
  end

  # 设置禁用菜单
  def command_135
    "$game_system.menu_disabled = #{@params[0] == 0}"
  end

  # 设置禁用遇敌
  def command_136
    "$game_system.encounter_disabled = #{@params[0] == 0}
    $game_player.make_encounter_count"
  end

  # 设置禁用整队
  def command_137
    "$game_system.formation_disabled = #{@params[0] == 0}"
  end

  # 场所移动
  def command_201
    if @params[0] == 0                      # 直接指定
      map_id = @params[1]
      x = @params[2]
      y = @params[3]
    else                                    # 变量指定
      map_id = "$game_variables[#{@params[1]}]"
      x = "$game_variables[#{@params[2]}]"
      y = "$game_variables[#{@params[3]}]"
    end 
    "
    return if $game_party.in_battle
    Fiber.yield while $game_player.transfer? || $game_message.visible
    $game_player.reserve_transfer(#{map_id}, #{x}, #{y}, #{@params[4]})
    $game_temp.fade_type = #{@params[5]}
    Fiber.yield while $game_player.transfer?
    "
  end

  # 设置载具位置
  def command_202
    if @params[1] == 0                      # 直接指定
      map_id = @params[2]
      x = @params[3]
      y = @params[4]
    else                                    # 变量指定
      map_id = "$game_variables[#{@params[2]}]"
      x = "$game_variables[#{@params[3]}]"
      y = "$game_variables[#{@params[4]}]"
    end
    "vehicle = $game_map.vehicles[#{@params[0]}]
    vehicle.set_location(#{map_id}, #{x}, #{y}) if vehicle"
  end

  # 地图卷动
  def command_204
    "return if $game_party.in_battle
    Fiber.yield while $game_map.scrolling?
    $game_map.start_scroll(#{@params[0]}, #{@params[1]}, #{@params[2]})"
  end

  # 更改透明状态
  def command_211
    "$game_player.transparent = #{@params[0] == 0}"
  end

  # 显示动画
  def command_212
    "character = get_character(#{@params[0]})
    if character
      character.animation_id = #{@params[1]}
      #{'Fiber.yield while character.animation_id > 0' if @params[2]}
    end"
  end

  # 显示心情图标
  def command_213
    "character = get_character(#{@params[0]})
    if character
      character.balloon_id = #{@params[1]}
      #{'Fiber.yield while character.balloon_id > 0' if @params[2]}
    end"
  end

  # 更改队列前进
  def command_216
    "$game_player.followers.visible = #{@params[0] == 0}
    $game_player.refresh"
  end

  # 画面震动
  def command_225
    "screen.start_shake(#{@params[0]}, #{@params[1]}, #{@params[2]})
    #{"wait(#{@params[1]})" if @params[2]}"
  end

  # 等待
  def command_230
    "wait(#{@params[0]})"
  end

  # 显示图片
  def command_231
    if @params[3] == 0    # 直接指定
      x = @params[4]
      y = @params[5]
    else                  # 变量指定
      x = "$game_variables[#{@params[4]}]"
      y = "$game_variables[#{@params[5]}]"
    end
    "screen.pictures[#{@params[0]}].show(#{escape @params[1]},
      #{@params[2]}, #{x}, #{y}, #{@params[6]}, #{@params[7]},
      #{@params[8]}, #{@params[9]})"
  end

  # 移动图片
  def command_232
    if @params[3] == 0    # 直接指定
      x = @params[4]
      y = @params[5]
    else                  # 变量指定
      x = "$game_variables[#{@params[4]}]"
      y = "$game_variables[#{@params[5]}]"
    end
    "screen.pictures[#{@params[0]}].move(#{@params[2]}, #{x}, #{y},
      #{@params[6]}, #{@params[7]}, #{@params[8]}, 
      #{@params[9]}, #{@params[10]})
    #{"wait(#{@params[10]})" if @params[11]}"
  end

  # 旋转图片
  def command_233
    "screen.pictures[#{@params[0]}].rotate(#{@params[1]})"
  end

  # 消除图片
  def command_235
    "screen.pictures[#{@params[0]}].erase"
  end

  # 设置天气
  def command_236
    "return if $game_party.in_battle
    screen.change_weather(#{@params[0]}, #{@params[1]}, #{@params[2]})
    #{"wait(#{@params[2]})" if @params[3]}"
  end

  # 淡出 BGM
  def command_242
    "RPG::BGM.fade(#{@params[0] * 1000})"
  end

  # 淡出 BGS 
  def command_246
    "RPG::BGS.fade(#{@params[0] * 1000})"
  end

  # 播放影像
  def command_261
    name = @params[0]
    unless name.empty?
      name = 'Movies/' + escape(name)
      "Fiber.yield while $game_message.visible
      Fiber.yield
      Graphics.play_movie(#{name})"
    end
  end

  # 更改地图名称显示
  def command_281
    "$game_map.name_display = #{@params[0] == 0}"
  end

  # 更改图块组
  def command_282
    "$game_map.change_tileset(#{@params[0]})"
  end

  # 更改战场背景
  def command_283
    name = "#{escape(@params[0])}, #{escape(@params[1])}"
    "$game_map.change_battleback(#{name})"
  end

  # 更改远景
  def command_284
    "$game_map.change_parallax(#{escape @params[0]},
      #{@params[1]}, #{@params[2]}, #{@params[3]}, #{@params[4]})"
  end

  # 获取指定位置的信息
  def command_285
    if @params[2] == 0      # 直接指定
      x = @params[3]
      y = @params[4]
    else                    # 变量指定
      x = "$game_variables[#{@params[3]}]"
      y = "$game_variables[#{@params[4]}]"
    end
    value =
    case @params[1]
    when 0      # 地形标志
      "$game_map.terrain_tag(#{x}, #{y})"
    when 1      # 事件 ID
      "$game_map.event_id_xy(#{x}, #{y})"
    when 2..4   # 图块 ID
      "$game_map.tile_id(#{x}, #{y}, #{@params[1] - 2})"
    else        # 区域 ID
      "$game_map.region_id(#{x}, #{y})"
    end
    "$game_variables[#{@params[0]}] = #{value}"
  end

  # 战斗的处理
  def command_301
    if @params[0] == 0                      # 直接指定
      troop_id = @params[1]
    elsif @params[0] == 1                   # 变量指定
      troop_id = "$game_variables[#{@params[1]}]"
    else                                    # 地图指定的敌群
      troop_id = '$game_player.make_encounter_troop_id'
    end
    ret = "
    __battle_result = 0
    return if $game_party.in_battle
    if $data_troops[#{troop_id}]
      BattleManager.setup(#{troop_id}, #{@params[2]}, #{@params[3]})
      BattleManager.event_proc = Proc.new { |n| __battle_result = n }
      $game_player.make_encounter_count
      SceneManager.call(Scene_Battle)
    end
    Fiber.yield
    "
    if next_code == 601 # 存在分支
      next_command!
      ret << "case __battle_result\n"
      until current_code == 604 # 分支结束
        ret << "when #{current_code - 601}\n" <<
          translate_branch(current_indent) << "\n"
      end
      ret << "end\n"
    end
    ret
  end

  # 商店的处理
  def command_302
    goods = [@params]
    while next_event_code == 605
      goods.push(next_params!)
    end
    ret = "
    return if $game_party.in_battle
    SceneManager.call(Scene_Shop)
    SceneManager.scene.prepare(#{escape goods}, @params[4])
    Fiber.yield
    "
  end

  # 名字输入的处理
  def command_303
    return '' unless $data_actors[@params[0]]
    "return if $game_party.in_battle
    SceneManager.call(Scene_Name)
    SceneManager.scene.prepare(#{@params[0]}, #{@params[1]})
    Fiber.yield"
  end

  # 更换装备
  def command_319
    "actor = $game_actors[#{@params[0]}]
    actor.change_equip_by_id(#{@params[1]}, #{@params[2]}) if actor"
  end

  # 更改名字
  def command_320
    "actor = $game_actors[#{@params[0]}]
    actor.name = #{escape @params[1]} if actor"
  end

  # 更改职业
  def command_321
    return '' unless $data_classes[@params[1]]
    "actor = $game_actors[#{@params[0]}]
    actor.change_class(#{@params[1]}) if actor"
  end

  # 更改称号
  def command_324
    "actor = $game_actors[#{@params[0]}]
    actor.nickname = #{escape @params[1]} if actor"
  end

  # 脚本
  def command_355
    escape_script(@params[0])
  end

  # 空指令
  def command_0
    'nil'
  end

  # 脚本数据
  alias_method :command_655, :command_355


  delegate_command 103      # 数值输入的处理
  delegate_command 104      # 物品选择的处理

  delegate_command 125      # 增减金钱
  delegate_command 126      # 增减物品
  delegate_command 127      # 增减武器
  delegate_command 128      # 增减护甲

  delegate_command 132      # 更改战斗 BGM
  delegate_command 133      # 更改战斗结束 ME 

  delegate_command 138      # 更改窗口色调

  delegate_command 203      # 设置事件位置
  delegate_command 205      # 设置移动路径
  delegate_command 206, nil # 载具乘降
  delegate_command 214, nil # 暂时消除事件
  delegate_command 217, nil # 集合队伍成员

  delegate_command 221, nil # 淡出画面
  delegate_command 222, nil # 淡入画面
  delegate_command 223      # 更改画面色调
  delegate_command 224      # 画面闪烁

  delegate_command 234      # 更改图片的色调

  delegate_command 241      # 播放 BGM
  delegate_command 243, nil # 记忆 BGM
  delegate_command 244, nil # 恢复 BGM
  delegate_command 245      # 播放 BGS
  delegate_command 249      # 播放 ME
  delegate_command 250      # 播放 SE
  delegate_command 251, nil # 停止 SE

  delegate_command 311      # 增减 HP
  delegate_command 312      # 增减 MP
  delegate_command 313      # 更改状态
  delegate_command 314      # 完全恢复
  delegate_command 315      # 增减经验值
  delegate_command 316      # 增减等级
  delegate_command 317      # 增减能力值
  delegate_command 318      # 增减技能
  delegate_command 322      # 更改角色图像
  delegate_command 323      # 更改载具的图像

  delegate_command 331      # 增减敌人 HP
  delegate_command 332      # 增减敌人 MP
  delegate_command 333      # 更改敌人状态
  delegate_command 334      # 敌人完全恢复
  delegate_command 335      # 敌人出现
  delegate_command 336      # 敌人变身
  delegate_command 337      # 显示战斗动画
  delegate_command 339      # 强制战斗行动
  delegate_command 340, nil # 终止战斗

  delegate_command 351, nil # 打开菜单画面
  delegate_command 352, nil # 打开存档画面
  delegate_command 353, nil # 游戏结束
  delegate_command 354, nil # 返回标题画面
end