

module Taroxd end

module Taroxd::Def

  # 导入
  Singleton = Module.new { Object.send :include, self }
  Module.send :include, self

  # 获取方法的访问限制
  def get_access_control(sym)
    return :public    if public_method_defined?    sym
    return :protected if protected_method_defined? sym
    return :private   if private_method_defined?   sym
    nil
  end

  template = lambda do |singleton|
    if singleton
      klass = 'singleton_class'
      get_method = 'method'
      define = 'define_singleton_method'
    else
      klass = 'self'
      get_method = 'instance_method'
      define = 'define_method'
    end
    %(
      def <name>(sym, hook = nil, &b)
        access = #{klass}.get_access_control sym
        old = #{get_method} sym
        if b
          #{define} sym, &b
          hook = #{get_method} sym
        end
        if hook.respond_to? :to_sym
          hook = hook.to_sym
          #{define} sym do |*args, &block|
            <pattern_sym>
          end
        elsif hook.respond_to? :call
          #{define} sym do |*args, &block|
            <pattern_call>
          end
        elsif hook.kind_of? UnboundMethod
          #{define} sym do |*args, &block|
            <pattern_unbound>
          end
        end
        #{klass}.send access, sym
        sym
      end
    )
  end

  # 保存模板和替换 'hook(' 字符串的字符
  template = {false => template.call(false), true => template.call(true)}

  # 替换掉 pattern 中的语法
  gsub_pattern = lambda do |pattern, singleton|
    old = singleton ? 'old' : 'old.bind(self)'
    pattern.gsub('*', '*args, &block')
           .gsub(/old(\()?/) { $1 ? "#{old}.call(" : old }
  end

  # 存入代替 "hook(" 的字符串
  template['sym']     = '__send__(hook, '
  template['call']    = 'hook.call('
  template['unbound'] = 'hook.bind(self).call('

  # 获取定义方法内容的字符串
  code = lambda do |name, pattern, singleton|
    pattern = gsub_pattern.call(pattern, singleton)
    template[singleton]
      .sub('<name>', name)
      .gsub(/<pattern_(\w+?)>/) { pattern.gsub('hook(', template[$1]) }
  end

  main = TOPLEVEL_BINDING.eval('self')

  # 定义 def_ 系列方法的方法
  define_singleton_method :def_ do |name, pattern|
    name = "#{__method__}#{name}"
    module_eval code.call(name, pattern, false)
    Singleton.module_eval code.call("singleton_#{name}", pattern, true)
    main.define_singleton_method name, &Kernel.method(name)
  end

  # 实际定义 def_ 系列的方法
  def_ :after,  'ret = old(*); hook(*); ret'
  def_ :after!, 'old(*); hook(*)'
  def_ :before, 'hook(*); old(*)'
  def_ :with,   'hook(old(*), *)'
  def_ :chain,  'hook(old, *)'
  def_ :and,    'old(*) && hook(*)'
  def_ :or,     'old(*) || hook(*)'
  def_ :if,     'hook(*) && old(*)'
  def_ :unless, '!hook(*) && old(*)'
end

module Taroxd::ReadNote

  # 导入
  include RPG
  BaseItem.extend        self
  Map.extend             self
  Event.extend           self
  Tileset.extend         self
  Class::Learning.extend self

  # 获取 note 的方法
  def note_method
    :note
  end

  # 事件名称作为备注
  class << Event
    def note_method
      :name
    end
  end

  # 备注模板
  def note_any(name, default, re, capture)
    name = name.to_s
    mark = name.slice!(/[?!]\Z/)
    if method_defined? name
      message = "already defined method `#{name}' for #{self}"
      raise NameError.new(message, name.to_sym)
    end
    re = "/<#{name.gsub(/_/, '\s*')}#{re.source}>/i"
    default = default.inspect
    class_eval %{
      def #{name}
        return @#{name} if instance_variable_defined? :@#{name}
        @#{name} = #{note_method} =~ #{re} ? (#{capture}) : (#{default})
      end
    }, __FILE__, __LINE__
    alias_method name + mark, name if mark
  end

  # 备注整数
  def note_i(name, default = 0)
    note_any(name, default, /\s*(-?\d+)/, '$1.to_i')
  end

  # 备注小数
  def note_f(name, default = 0.0)
    note_any(name, default, /\s*(-?\d+(?:\.\d+)?)/, '$1.to_f')
  end

  # 备注字符串
  def note_s(name, default = '')
    note_any(name, default, /\s*(\S.*)/, '$1')
  end

  # 备注是否匹配
  def note_bool(name)
    note_any(name, false, //, 'true')
  end
end

#==============================================================================
# ■ Taroxd::SpritesetDSL
#------------------------------------------------------------------------------
# 　简化导入精灵的模块。代码在 Spriteset_Map 和 Spriteset_Battle 中共用。
#   使用时，只需调用 use_sprite 方法即可。
#   例：use_sprite(Sprite_Xxx) { @viewport }
#==============================================================================

module Taroxd::SpritesetDSL
  #------------------------------------------------------------------------
  # ● 方法名
  #------------------------------------------------------------------------
  CREATE_METHOD_NAME  = :create_taroxd_sprites
  UPDATE_METHOD_NAME  = :update_taroxd_sprites
  DISPOSE_METHOD_NAME = :dispose_taroxd_sprites
  #------------------------------------------------------------------------
  # ● 定义管理精灵的方法
  #------------------------------------------------------------------------
  def self.extended(klass)
    klass.class_eval do
      sprites = nil

      define_method CREATE_METHOD_NAME do
        sprites = klass.sprite_list.map do |sprite_class, get_args|
          if get_args
            sprite_class.new(*instance_eval(&get_args))
          else
            sprite_class.new
          end
        end
      end

      define_method(UPDATE_METHOD_NAME)  { sprites.each(&:update)  }
      define_method(DISPOSE_METHOD_NAME) { sprites.each(&:dispose) }
    end
  end
  #--------------------------------------------------------------------------
  # ● 声明使用一个精灵
  #--------------------------------------------------------------------------
  def use_sprite(klass, &get_args)
    sprite_list.push [klass, get_args]
  end
  #--------------------------------------------------------------------------
  # ● 使用精灵的列表
  #--------------------------------------------------------------------------
  def sprite_list
    @_taroxd_use_sprite ||= []
  end
  #--------------------------------------------------------------------------
  # ● 在一系列方法上触发钩子
  #--------------------------------------------------------------------------
  def sprite_method_hook(name)
    def_after :"create_#{name}",  CREATE_METHOD_NAME
    def_after :"update_#{name}",  UPDATE_METHOD_NAME
    def_after :"dispose_#{name}", DISPOSE_METHOD_NAME
  end
end

class Fixnum < Integer
  #---------------------------------------------------------------------------
  # ● 获取 id
  #---------------------------------------------------------------------------
  def id; self; end
end

module Enumerable
  #---------------------------------------------------------------------------
  # ● 元素之和
  #---------------------------------------------------------------------------
  def sum(base = 0)
    block_given? ? inject(base) {|a, e| a + yield(e) } : inject(base, :+)
  end
  #---------------------------------------------------------------------------
  # ● 元素之积
  #---------------------------------------------------------------------------
  def pi(base = 1)
    block_given? ? inject(base) {|a, e| a * yield(e) } : inject(base, :*)
  end
  #---------------------------------------------------------------------------
  # ● 元素之平均值(base可取0.0)
  #---------------------------------------------------------------------------
  def average(base = 0, &block)
    sum(base, &block) / [count, 1].max
  end
end

class RPG::Enemy < RPG::BaseItem 
  #---------------------------------------------------------------------------
  # ● 初始化宽高
  #---------------------------------------------------------------------------
  def init_width_height
    bitmap = Bitmap.new("Graphics/Battlers/#{@battler_name}")
    @width = bitmap.width
    @height = bitmap.height
    bitmap.dispose
  end
  #---------------------------------------------------------------------------
  # ● 获取宽度
  #---------------------------------------------------------------------------
  def width
    return @width if @width
    init_width_height
    @width
  end
  #---------------------------------------------------------------------------
  # ● 获取高度
  #---------------------------------------------------------------------------
  def height
    return @height if @height
    init_width_height
    @height
  end
end

class Game_BaseItem
  #--------------------------------------------------------------------------
  # ● 获取属性
  #--------------------------------------------------------------------------
  attr_reader :item_id
  alias id item_id
end

class Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 最大 TP
  #--------------------------------------------------------------------------
  def mtp; max_tp; end
  #--------------------------------------------------------------------------
  # ● 获取 TP 的比率
  #--------------------------------------------------------------------------
  def tp_rate; @tp.fdiv(max_tp); end
  #--------------------------------------------------------------------------
  # ● 更改 TP
  #--------------------------------------------------------------------------
  def_after(:tp=) {|_| refresh }
end

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # ● 迭代拥有备注的实例
  #--------------------------------------------------------------------------
  def note_objects
    return to_enum(__method__) unless block_given?
    states.each {|e| yield e }
    equips.each {|e| yield e if e }
    skills.each {|e| yield e }
    yield data_object
    yield self.class if actor?
  end
  #--------------------------------------------------------------------------
  # ● TP 自动恢复
  #--------------------------------------------------------------------------
  def regenerate_tp; self.tp += max_tp * trg; end
  #--------------------------------------------------------------------------
  # ● 获取数据库实例
  #--------------------------------------------------------------------------
  def data_object; end
  #--------------------------------------------------------------------------
  # ● 获取备注
  #--------------------------------------------------------------------------
  def note; data_object.note; end
  #--------------------------------------------------------------------------
  # ● 获取 ID
  #--------------------------------------------------------------------------
  def id; data_object.id; end
  #--------------------------------------------------------------------------
  # ● 获取技能实例的数组
  #--------------------------------------------------------------------------
  def skills
    (basic_skills | added_skills).sort.map {|id| $data_skills[id] }
  end
  #--------------------------------------------------------------------------
  # ● 空数组
  #--------------------------------------------------------------------------
  def equips; []; end
  alias weapons equips
  alias armors  equips
  alias basic_skills equips
  #--------------------------------------------------------------------------
  # ● 是否拥有技能
  #--------------------------------------------------------------------------
  def skill?(skill)
    basic_skills.include?(skill.id) || added_skills.include?(skill.id)
  end
  #--------------------------------------------------------------------------
  # ● 是否学会技能
  #--------------------------------------------------------------------------
  def skill_learn?(skill)
    skill.kind_of?(RPG::Skill) && basic_skills.include?(skill.id)
  end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # ● 获取数据库实例
  #--------------------------------------------------------------------------
  alias data_object actor
  #--------------------------------------------------------------------------
  # ● 是否装备武器
  #--------------------------------------------------------------------------
  def weapon?(weapon)
    @equips.any? {|item| item.id == weapon.id && item.is_weapon? }
  end
  #--------------------------------------------------------------------------
  # ● 是否装备护甲
  #--------------------------------------------------------------------------
  def armor?(armor)
    @equips.any? {|item| item.id == armor.id && item.is_armor? }
  end
  private
  #--------------------------------------------------------------------------
  # ● 获取基本技能 ID 所构成的数组
  #--------------------------------------------------------------------------
  def basic_skills; @skills; end
end

class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # ● 获取数据库实例
  #--------------------------------------------------------------------------
  alias data_object enemy
  #--------------------------------------------------------------------------
  # ● 获取敌人 ID
  #--------------------------------------------------------------------------
  attr_reader :enemy_id
  alias id enemy_id
  #--------------------------------------------------------------------------
  # ● 获取敌人的位图（不自动释放）
  #--------------------------------------------------------------------------
  def bitmap; Cache.battler(battler_name, battler_hue); end
  #--------------------------------------------------------------------------
  # ● 获取战斗图的宽度
  #--------------------------------------------------------------------------
  def width; enemy.width; end
  #--------------------------------------------------------------------------
  # ● 获取战斗图的高度
  #--------------------------------------------------------------------------
  def height; enemy.height; end
  #--------------------------------------------------------------------------
  # ● 获取基本技能 ID 所构成的数组
  #--------------------------------------------------------------------------
  def basic_skills; enemy.actions.map(&:skill_id); end
end

class Game_Actors
  include Enumerable
  #--------------------------------------------------------------------------
  # ● 迭代
  #--------------------------------------------------------------------------
  def each
    return to_enum(__method__) unless block_given?
    @data.each {|actor| yield actor if actor }
    self
  end
  #--------------------------------------------------------------------------
  # ● 是否包含
  #--------------------------------------------------------------------------
  def include?(actor)
    @data[actor.id]
  end
end

class Game_Unit
  include Enumerable
  #--------------------------------------------------------------------------
  # ● 转为数组
  #--------------------------------------------------------------------------
  def to_a; members; end
  #--------------------------------------------------------------------------
  # ● 迭代每位成员
  #--------------------------------------------------------------------------
  def each
    return to_enum(__method__) unless block_given?
    members.each {|battler| yield battler }
    self
  end
  alias each_member each
  #--------------------------------------------------------------------------
  # ● 获取成员
  #--------------------------------------------------------------------------
  def [](*args); members[*args]; end
  alias slice []
  #--------------------------------------------------------------------------
  # ● 是否为空
  #--------------------------------------------------------------------------
  def empty?; members.empty?; end
  #--------------------------------------------------------------------------
  # ● 获取成员人数
  #--------------------------------------------------------------------------
  def size; members.size; end
  alias length size
end

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # ● 角色是否存在
  #--------------------------------------------------------------------------
  def include?(actor)
    @actors.include?(actor.id)
  end
end

class Game_Map
  #--------------------------------------------------------------------------
  # ● 获取 id
  #--------------------------------------------------------------------------
  attr_reader :map_id
  alias id map_id
  #--------------------------------------------------------------------------
  # ● 获取数据库实例
  #--------------------------------------------------------------------------
  def data_object; @map; end
  #--------------------------------------------------------------------------
  # ● 备注
  #--------------------------------------------------------------------------
  def note; @map.note; end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  extend Taroxd::SpritesetDSL
  sprite_method_hook :timer
  #--------------------------------------------------------------------------
  map_id = nil
  #--------------------------------------------------------------------------
  # ● 更新地图 ID
  #--------------------------------------------------------------------------
  update_map_id = -> { map_id = $game_map.map_id }
  def_after :initialize, update_map_id
  def_after :update,     update_map_id
  #--------------------------------------------------------------------------
  # ● 地图是否变更
  #--------------------------------------------------------------------------
  define_method(:map_changed?) { map_id != $game_map.map_id }
end

class Spriteset_Battle
  extend Taroxd::SpritesetDSL
  sprite_method_hook :timer
end