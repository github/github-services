module Test
  module Unit
    class TestCase
      def kcode(code)
        begin
          TMail.KCODE = code
          yield
        ensure
          TMail.KCODE = 'NONE'
        end
      end
    end
  end
end
