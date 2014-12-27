
#----------------------------------------------------------------------------
# ● require Taroxd基础设置
#    无限图层显示系统 Unlimited Layers Display System By Taroxd
#----------------------------------------------------------------------------
#
#  使用方法：导入此脚本后，在地图上备注如下内容。
#
#  <ulds=filename>
#    x: X坐标（公式，默认为 0）
#    y: Y坐标（公式，默认为 0）
#    z: Z坐标（整数，默认为 10，可以设置为 -100 来当作远景图使用）
#    zoom: 缩放倍率（公式，默认为 1。缩放的原点为画面左上角。）
#    zoom_x: 横向缩放倍率（公式，默认为 zoom）
#    zoom_y: 纵向缩放倍率（公式，默认为 zoom）
#    opacity: 不透明度（公式，默认为 255）
#    blend_type: 合成方式（0、1、2，默认为 0）（0：正常、1：加法、2：减法）
#    scroll: 跟随地图卷动的速度（实数，默认为 32。）
#    scroll_x: 跟随地图横向卷动的速度（实数，默认为 scroll）
#    scroll_y：跟随地图纵向卷动的速度（实数，默认为 scroll）
#    loop:（循环。冒号后面不需要填写任何东西。）
#    visible: 图片是否显示（公式，默认为 true）
#    path: 图片的路径名（默认为 Parallaxes）
#    update: 图片显示时，每帧执行的更新代码（公式，默认为 t += 1）
#  </ulds>
#
#  其中 filename 是图片文件名（无需扩展名），放入 Parallaxes 文件夹内
#  这个文件夹可以通过 path 设置更改
#
#  在 <ulds=filename> 和 </ulds> 中间的部分均为选填。不填则自动设为默认值。
#  每一个设置项只能写一行。（地图备注没有单行长度限制）
#  每一行只能写一个设置项。
#  一般来说，正常使用时大部分都是不需要设置的。
#
#  设置项目中的“公式”表示，这一个设置项可以像技能的伤害公式一样填写。
#  可用 t 表示当前已经显示的帧数，s[n], v[n] 分别表示 n 号开关和 n 号变量。
#
#----------------------------------------------------------------------------

class Taroxd::ULDS
  DEFAULT_PATH = 'Parallaxes'               # 图片文件的默认路径
  DEFAULT_Z = 10                            # 默认的 z 值
  RE_OUTER = /<ulds=(.+?)>(.*?)<\/ulds>/mi  # 读取备注用的正则表达式
  RE_INNER = /(\w+) *: *(.*)/               # 读取设置用的正则表达式
  include Math
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(settings, viewport = nil)
    @settings = settings
    init_picture(viewport)
    init_const_attributes
    init_update_method
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose
    @holder.bitmap.dispose
    @holder.dispose
  end
  #--------------------------------------------------------------------------
  # ● 私有方法
  #--------------------------------------------------------------------------
  private
  #--------------------------------------------------------------------------
  # ● 初始化图片
  #--------------------------------------------------------------------------
  def init_picture(viewport)
    @holder = (extract('loop') ? Plane : Sprite).new(viewport)
    @holder.bitmap = Bitmap.new(
      "Graphics/#{extract('path', DEFAULT_PATH)}/#{extract('name')}")
  end
  #--------------------------------------------------------------------------
  # ● 初始化属性（常数）
  #--------------------------------------------------------------------------
  def init_const_attributes
    @holder.z = extract('z', DEFAULT_Z).to_i
    @scroll_x = extract('scroll_x', 32.0).to_f
    @scroll_y = extract('scroll_y', 32.0).to_f
    @holder.blend_type = extract('blend_type', 0).to_i
  end
  #--------------------------------------------------------------------------
  # ● 初始化更新方法
  #--------------------------------------------------------------------------
  def init_update_method
    s = $game_switches
    v = $game_variables
    t = 0
    visible = true
    eval %{
      define_singleton_method :update do
        #{update_visibility_code}
        return unless visible
        #{update_position_code 'x'}
        #{update_position_code 'y'}
        #{update_attribute_code 'zoom_x'}
        #{update_attribute_code 'zoom_y'}
        #{update_attribute_code 'opacity'}
        #{update_time_code}
      end
    }
  end
  #--------------------------------------------------------------------------
  # ● 更新位置的代码
  #--------------------------------------------------------------------------
  def update_position_code(key)
    formula = extract(key)
    formula &&= " - (#{formula})"
    "@holder.o#{key} = $game_map.display_#{key} * @scroll_#{key}#{formula}"
  end
  #--------------------------------------------------------------------------
  # ● 更新属性的代码
  #--------------------------------------------------------------------------
  def update_attribute_code(key)
    formula = extract(key)
    formula && "@holder.#{key} = (#{formula})"
  end
  #--------------------------------------------------------------------------
  # ● 更新是否显示的代码
  #--------------------------------------------------------------------------
  def update_visibility_code
    formula = extract('visible')
    formula && "visible = @holder.visible = (#{formula})"
  end
  #--------------------------------------------------------------------------
  # ● 更新时间的代码
  #--------------------------------------------------------------------------
  def update_time_code
    extract('update', 't += 1')
  end
  #--------------------------------------------------------------------------
  # ● 获取备注中的设定值
  #--------------------------------------------------------------------------
  def extract(key, default = nil)
    return @settings[key] if @settings.key?(key)
    return @settings[$1] if /(.+)_[xy]\Z/ =~ key && @settings.key?($1)
    default
  end
end

class Spriteset_Map
  #--------------------------------------------------------------------------
  # ● 创建
  #--------------------------------------------------------------------------
  def create_ulds
    @ulds =
    $game_map.note.scan(Taroxd::ULDS::RE_OUTER).map do |name, contents|
      settings = Hash[contents.scan(Taroxd::ULDS::RE_INNER)]
      settings['name'] = name
      settings.each_value(&:chomp!)
      Taroxd::ULDS.new(settings, @viewport1)
    end
  end
  #--------------------------------------------------------------------------
  # ● 刷新
  #--------------------------------------------------------------------------
  def refresh_ulds
    dispose_ulds
    create_ulds
  end
  #--------------------------------------------------------------------------
  # ● 更新
  #--------------------------------------------------------------------------
  def update_ulds
    refresh_ulds if map_changed?
    @ulds.each(&:update)
  end
  #--------------------------------------------------------------------------
  # ● 释放
  #--------------------------------------------------------------------------
  def dispose_ulds
    @ulds.each(&:dispose)
  end
  #--------------------------------------------------------------------------
  # ● 导入
  #--------------------------------------------------------------------------
  def_before :create_parallax,  :create_ulds
  def_before :update_parallax,  :update_ulds
  def_before :dispose_parallax, :dispose_ulds
end