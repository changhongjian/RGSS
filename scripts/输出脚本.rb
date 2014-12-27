
#==============================================================================
# ★ 输出脚本
#==============================================================================

path = 'F:/RGSS/scripts/'
ext  = '.rb'

output = lambda do
  $RGSS_SCRIPTS.each_with_index do |(_, tag, _, contents), i|
    Dir.mkdir(path) unless File.directory?(path)
    next unless tag.start_with?('★')..tag.start_with?('☆')
    next if contents.force_encoding('utf-8').empty?
    filename = tag.delete('- /:*?"<>|\\').capitalize
    if filename.empty?
      msgbox "Warning: script #{i} with an invalid tag"
    else
      File.open("#{path}#{filename}#{ext}", 'wb') do |f|
        f.write contents
      end
    end
  end
  msgbox 'Scripts output successfully.'
  exit
end

output.call if $TEST