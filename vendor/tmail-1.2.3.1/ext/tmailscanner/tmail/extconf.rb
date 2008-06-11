require 'mkmf'
require 'rbconfig'

extension_name = 'tmailscanner'

windows = (/djgpp|(cyg|ms|bcc)win|mingw/ =~ RUBY_PLATFORM)

# For now use pure Ruby tmailscanner if on Windows, since 
# most Window's users don't have developer tools needed.

if (ENV['NORUBYEXT'] == 'true' || windows)
  if windows
    File.open('make.bat', 'w') do |f|
      f << 'echo Native extension will be omitted.'
    end
    File.open('nmake.bat', 'w') do |f|
      f << 'echo Native extension will be omitted.'
    end
  end
  File.open('Makefile', 'w') do |f|
    f << "all:\n"
    f << "install:\n"
  end
else
  #dir_config(extension_name)
  if windows && ENV['make'].nil?
    $LIBS += " msvcprt.lib"
  else
    $CFLAGS += " -D_FILE_OFFSET_BITS=64"  #???
  end
  create_makefile(extension_name)
end

