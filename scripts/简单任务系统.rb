
#----------------------------------------------------------------------------
# ● require Taroxd基础设置
#----------------------------------------------------------------------------

class Taroxd::Task
  #--------------------------------------------------------------------------
  # ● 任务设定
  #--------------------------------------------------------------------------
  LIST = [
    # 在此设置任务的内容。设置方式请参考 Taroxd::Task 的定义。
  ]
  COMPLETED_PREFIX = '\I[125]'      # 任务完成时的前缀，不需要可设置为 ''
  ONGOING_PRIFIX   = '\I[126]'      # 任务进行中的前缀，不需要可设置为 ''
  COMMAND          = '任务'         # 菜单上的指令名，不需要可设置为 nil
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(id, name, description = '', goal = 1)
    @id, @name, @description, @goal = id, name, description, goal
  end
  attr_reader :description
  #--------------------------------------------------------------------------
  # ● 任务名称
  #--------------------------------------------------------------------------
  def name
    (completed? ? COMPLETED_PREFIX : ONGOING_PRIFIX) + @name
  end
  #--------------------------------------------------------------------------
  # ● 任务是否开始
  #--------------------------------------------------------------------------
  def started?
    $game_switches[@id]
  end
  #--------------------------------------------------------------------------
  # ● 任务是否完成
  #--------------------------------------------------------------------------
  def completed?
    $game_variables[@id] >= @goal
  end
  #--------------------------------------------------------------------------
  # ● 设置任务列表
  #--------------------------------------------------------------------------
  LIST.map! {|args| new(*args) }
  #--------------------------------------------------------------------------
  # ● 获取任务列表
  #--------------------------------------------------------------------------
  def self.list
    LIST.select(&:started?)
  end
end

class Window_TaskList < Window_Selectable
  Task = Taroxd::Task
  #--------------------------------------------------------------------------
  # ● 初始化
  #--------------------------------------------------------------------------
  def initialize(y)
    super(0, y, Graphics.width, Graphics.height - y)
    select Task.list.index {|task| !task.completed? }
    refresh
  end
  #--------------------------------------------------------------------------
  # ● 获取列数
  #--------------------------------------------------------------------------
  def col_max
    2
  end
  #--------------------------------------------------------------------------
  # ● 获取项目数
  #--------------------------------------------------------------------------
  def item_max
    Task.list.size
  end
  #--------------------------------------------------------------------------
  # ● 绘制项目
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect_for_text(index)
    draw_text_ex(rect.x, rect.y, Task.list[index].name)
  end
  #--------------------------------------------------------------------------
  # ● 更新帮助窗口
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_text(Task.list[index].description)
  end
end

class Scene_Task < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 开始处理
  #--------------------------------------------------------------------------
  def start
    super
    create_help_window
    create_list_window
  end
  #--------------------------------------------------------------------------
  # ● 创建任务列表窗口
  #--------------------------------------------------------------------------
  def create_list_window
    @list_window = Window_TaskList.new(@help_window.height)
    @list_window.help_window = @help_window
    @list_window.set_handler(:cancel, method(:return_scene))
    @list_window.activate
  end
end

if Taroxd::Task::COMMAND

class Window_MenuCommand < Window_Command
  #--------------------------------------------------------------------------
  # ● 独自添加指令用
  #--------------------------------------------------------------------------
  def_after :add_original_commands do
    add_command(Taroxd::Task::COMMAND, :task, !Taroxd::Task.list.empty?)
  end
end

class Scene_Menu < Scene_MenuBase
  #--------------------------------------------------------------------------
  # ● 生成指令窗口
  #--------------------------------------------------------------------------
  def_after :create_command_window do
    @command_window.set_handler(:task, method(:command_task))
  end
  #--------------------------------------------------------------------------
  # ● 指令“任务”
  #--------------------------------------------------------------------------
  def command_task
    SceneManager.call(Scene_Task)
  end
end

end # if Taroxd::Task::COMMAND