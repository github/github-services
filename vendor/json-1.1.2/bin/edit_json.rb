#!/usr/bin/env ruby
$KCODE = 'U'
require 'json/editor'

filename, encoding = ARGV
JSON::Editor.start(encoding) do |window|
  if filename
    window.file_open(filename)
  end
end
  # vim: set et sw=2 ts=2:
