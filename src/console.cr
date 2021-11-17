require "./shatter"

puts "1/6: MSA"
msa = Shatter::MSA.new
puts "2/6: Token"
token = msa.refresh ARGV[2]
puts "3/6: XBL"
xbl = msa.xbl token
puts "4/6: XSTS"
xsts = msa.xsts xbl
puts "5/6: Minecraft"
mc_token = msa.minecraft xsts
puts "6/6: Checking profile"
profile = msa.profile mc_token
registry, known_blocks = Shatter.local_registry
Shatter::Connection.new(ARGV[0], ARGV[1].to_i, registry, known_blocks, mc_token.access_token, profile).run
sleep
