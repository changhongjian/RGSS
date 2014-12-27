
#--------------------------------------------------------------------------
# ● require Taroxd基础设置
#--------------------------------------------------------------------------

Taroxd::Global = {}
symbol = :taroxd_global

#------------------------------------------------------------------------
# ● 新游戏
#------------------------------------------------------------------------
on_new_game = Taroxd::Global.method(:clear)
#------------------------------------------------------------------------
# ● 存档
#------------------------------------------------------------------------
on_save = lambda do |contents|
  contents[symbol] = Taroxd::Global
  contents
end
#------------------------------------------------------------------------
# ● 读档
#------------------------------------------------------------------------
on_load = lambda do |contents|
  data = contents[symbol]
  Taroxd::Global.replace(data) if data
end

DataManager.singleton_def_before :setup_new_game,        on_new_game
DataManager.singleton_def_with   :make_save_contents,    on_save
DataManager.singleton_def_after  :extract_save_contents, on_load
