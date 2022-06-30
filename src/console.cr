require "./shatter"

# Get the translation keys ready while doing the rest of authentication
tl_key = Channel(Bool).new
spawn do
  Shatter::Chat::Reader::MojangAssetLangReader.new.keys
  tl_key.send true
end
sleep 0

puts "1/8: MSA"
msa = Shatter::MSA.new
puts "2/8: Token"
token = msa.refresh ARGV[3]
puts "3/8: XBL"
xbl = msa.xbl token
puts "4/8: XSTS"
xsts = msa.xsts xbl
puts "5/8: Minecraft"
mc_token = msa.minecraft xsts
puts "6/8: Checking profile"
profile = msa.profile mc_token

puts "7/8: Priming registry"
registry, known_blocks = Shatter.local_registry
puts "8/8: Priming translation keys"
tl_key.receive

puts "Done! Connecting..."
Shatter::Connection.new(Shatter::Packet::Protocol::PROTOCOL_NAMES[ARGV[0]], ARGV[1], ARGV[2].to_i, registry, known_blocks, mc_token.access_token, profile).run
sleep

