
#----------------------------------------------------------------------------
# ● require Taroxd基础设置
#    无限图层显示系统 Unlimited Layers Display System By Taroxd
#----------------------------------------------------------------------------
#
#  使用方法：导入此脚本后，在地图上备注如下内容。
#
#  <ulds=filename>
#    x: X坐标
#      公式，默认为 0
#    y: Y坐标
#      公式，默认为 0
#    z: Z坐标
#      公式，只计算一次，默认为 10，可以设置为 -100 来当作远景图使用
#    zoom: 缩放倍率
#      公式，默认为 1。缩放的原点为画面左上角。
#    zoom_x: 横向缩放倍率
#      公式，默认为 zoom
#    zoom_y: 纵向缩放倍率
#      公式，默认为 zoom
#    opacity: 不透明度
#      公式，默认为 255
#    blend_type: 合成方式
#      公式，只计算一次。默认为 0 （0：正常、1：加法、2：减法）
#    scroll: 图像跟随地图卷动的速度
#      实数，默认为 32。）
#    scroll_x: 图像跟随地图横向卷动的速度
#      实数，默认为 scroll
#    scroll_y：图像跟随地图纵向卷动的速度
#      实数，默认为 scroll
#    loop: 循环
#      冒号后面不需要填写任何东西。
#    visible: 图像是否显示
#      公式，默认为 true
#    path: 图像的路径名
#      默认为 Parallaxes
#    color: 合成的颜色
#      公式，只计算一次。默认为 Color.new(0, 0, 0, 0)
#    tone: 色调
#      公式，只计算一次。默认为 Tone.new(0, 0, 0, 0)
#    init: 初始化时，以 sprite 或 plane 为 self 执行的代码。
#      公式，默认为空
#    update: 图片显示时，每帧执行的更新代码
#      公式，默认为 t += 1
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
#  “只计算一次”表示，该公式只会在刚刚进入地图时计算一次，之后不会更新。
#  可用 t 表示当前已经显示的帧数，s[n], v[n] 分别表示 n 号开关和 n 号变量。
#
#  例：
#   <ulds=BlueSky>
#     x: t
#     scroll_x: 16
#     scroll_y: 64
#     loop:
#   </ulds>
#
#--------------------------------------------------------------------

module Taroxd::ULDS

  DEFAULT_PATH = 'Parallaxes'               # 图片文件的默认路径
  DEFAULT_Z = 10                            # 默认的 z 值
  RE_OUTER = /<ulds=(.+?)>(.*?)<\/ulds>/mi  # 读取备注用的正则表达式
  RE_INNER = /(\w+) *: *(.*)/               # 读取设置用的正则表达式

  class << self

    # 返回一个 sprite 或 plane
    def new(settings, viewport = nil)
      @settings = settings
      holder(viewport)
    end

    private

    def holder(viewport)
      (extract('loop') ? Plane : Sprite).new(viewport).tap do |holder|
        holder.bitmap = Bitmap.new(bitmap_filename)
        holder.instance_eval(init_holder_code, __FILE__, __LINE__)
      end
    end

    # 在一个 sprite 或 plane 的上下文中执行的代码。
    # 如果难以理解，请尝试输出这段代码来查看。
    def init_holder_code
      "extend Math
      #{binding_code}
      #{init_attr_code}
      #{define_update_code}
      #{define_dispose_code}
      #{extract 'init'}"
    end

    # 定义变量的代码
    def binding_code
      's = $game_switches
      v = $game_variables
      t = 0
      visible = true'
    end

    # 只计算一次的初始化代码
    def init_attr_code
      "#{set_attr_code 'z', DEFAULT_Z}
      #{set_attr_code 'blend_type'}
      #{set_attr_code 'color'}
      #{set_attr_code 'tone'}"
    end

    # 更新的代码
    def define_update_code
      %{
        define_singleton_method :update do
          #{set_visible_code}
          return unless visible
          #{set_attr_code 'zoom_x'}
          #{set_attr_code 'zoom_y'}
          #{set_attr_code 'opacity'}
          #{set_pos_code 'x'}
          #{set_pos_code 'y'}
          #{set_t_code}
        end
      }
    end

    # 释放的代码
    def define_dispose_code
      'def dispose
        bitmap.dispose
        super
      end'
    end

    # 设置位置的代码
    #   self.ox = $game_map.display_x * 32.0 / zoom_x - (formula)
    def set_pos_code(key)
      formula = extract(key)
      formula &&= " - (#{formula})"
      scroll = extract("scroll_#{key}", 32.0).to_f
      basic = "$game_map.display_#{key} * #{scroll} / zoom_#{key}"
      "self.o#{key} = #{basic}#{formula}"
    end

    # 设置属性的代码
    def set_attr_code(key, default = nil)
      formula = extract(key, default)
      formula && "self.#{key} = (#{formula})"
    end

    # 设置是否显示的代码
    def set_visible_code
      formula = extract('visible')
      formula && "visible = self.visible = (#{formula})"
    end

    # 设置时间的代码
    def set_t_code
      extract('update', 't += 1')
    end

    # 位图文件名
    def bitmap_filename
      "Graphics/#{extract('path', DEFAULT_PATH)}/#{extract('name')}"
    end

    # 获取备注中的设定值
    def extract(key, default = nil)
      return @settings[key] if @settings.key?(key)
      return @settings[$1] if /(.+)_[xy]\Z/ =~ key && @settings.key?($1)
      default
    end
  end
end

class Spriteset_Map

  def create_ulds
    @ulds =
    $game_map.note.scan(Taroxd::ULDS::RE_OUTER).map do |name, contents|
      settings = Hash[contents.scan(Taroxd::ULDS::RE_INNER)]
      settings['name'] = name
      settings.each_value(&:chomp!)
      Taroxd::ULDS.new(settings, @viewport1)
    end
  end

  def refresh_ulds
    dispose_ulds
    create_ulds
  end

  def update_ulds
    refresh_ulds if map_changed?
    @ulds.each(&:update)
  end

  def dispose_ulds
    @ulds.each(&:dispose)
  end

  def_before :create_parallax,  :create_ulds
  def_before :update_parallax,  :update_ulds
  def_before :dispose_parallax, :dispose_ulds

end