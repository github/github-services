unless defined?(BlankSlate)
  class BlankSlate < BasicObject; end if defined?(BasicObject)

  class BlankSlate #:nodoc:
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  end
end