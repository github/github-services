MAX = 1000

class Fixnum
  def prime?
    ('1' * self) !~ /^1?$|^(11+?)\1+$/
  end
end

class PrimeChecker
  def is_prime? number
    number.prime?
  end
end

prime_checker = PrimeChecker.new

(10_000...(10_000+MAX)).each do |n|
  prime_checker.is_prime? n
end
