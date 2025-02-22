puts "Testing native extension..."

a, b = 27362028616592833077810614538336061650596602259623245623188871925927275101952, 57097733966917585112089915289446881218887831888508524872740133297073405558528
f = ->(a,b){ DHashVips::IDHash.distance3_ruby a, b }

p as = [a.to_s(16).rjust(64,?0)].pack("H*").unpack("N*")
p bs = [b.to_s(16).rjust(64,?0)].pack("H*").unpack("N*")
puts as.zip(bs)[0,4].map{ |i,j| (i | j).to_s(2).rjust(32, ?0) }.zip \
     as.zip(bs)[4,4].map{ |i,j| (i ^ j).to_s(2).rjust(32, ?0) }
p DHashVips::IDHash.distance3 a, b
p f[a, b]
fail unless 17 == f[a, b]

s = [0, 1, 1<<63, (1<<63)+1, (1<<64)-1].each do |_|
  # p [_.to_s(16).rjust(64,?0)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
end
ss = s.repeated_permutation(4).map do |s1, s2, s3, s4|
  ((s1 << 192) + (s2 << 128) + (s3 << 64) + s4).tap do |_|
    # p [_.to_s(16).rjust(64,?0)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
  end
end
fail unless :distance3 == DHashVips::IDHash.method(:distance3).original_name
if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.4")
  check = lambda do |s1, s2|
    s1.is_a?(Bignum) && s2.is_a?(Bignum)
  end
else
  require "rbconfig/sizeof"
  check = lambda do |s1, s2|
    # https://github.com/ruby/ruby/commit/de2f7416d2deb4166d78638a41037cb550d64484#diff-16b196bc6bfe8fba63951420f843cfb4R10
    _FIXNUM_MAX = (1 << (8 * RbConfig::SIZEOF["long"] - 2)) - 1
    s1 > _FIXNUM_MAX && s2 > _FIXNUM_MAX
  end
end
ss.product ss do |s1, s2|
  next unless check.call s1, s2
  unless f[s1, s2] == DHashVips::IDHash.distance3_c(s1, s2)
    p [s1, s2]
    p [s1.to_s(16).rjust(64,?0)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
    p [s2.to_s(16).rjust(64,?0)].pack("H*").unpack("N*").map{ |_| _.to_s(2).rjust(32, ?0) }
    p [f[s1, s2], DHashVips::IDHash.distance3_c(s1, s2)]
    fail
  end
end
100000.times do
  s1, s2 = Array.new(2){ n = rand 256; ([?0] * n + [?1] * (256 - n)).shuffle.join.to_i 2 }
  fail unless DHashVips::IDHash.distance3(s1, s2) == DHashVips::IDHash.distance3_ruby(s1, s2)
end
