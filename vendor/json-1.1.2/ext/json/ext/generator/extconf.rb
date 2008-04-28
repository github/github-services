require 'mkmf'
require 'rbconfig'

if CONFIG['CC'] =~ /gcc/
  #$CFLAGS += ' -Wall -ggdb'
  $CFLAGS += ' -Wall'
end

create_makefile 'generator'
