require 'sinatra'
require 'colorize'
require 'active_support/time'
require 'yaml'
require_relative 'block'
require_relative 'client'
require_relative 'helpers'

PORT, PEER_PORT = ARGV.first(2)
set :port, PORT

$PEERS = ThreadSafe::Array.new([PORT])

PRIV_KEY, PUB_KEY = PKI.generate_key_pair

if PEER_PORT.nil?
  # You are the progenitor!
  $BLOCKCHAIN = BlockChain.new(PUB_KEY, PRIV_KEY)
else
  # You're just joining the network.
  $PEERS << PEER_PORT
end

every(3.seconds) do
  $PEERS.dup.each do |port|
    next if port == PORT

    puts "Gossiping about blockchain and peers with #{port.to_s.green}"
    gossip_with_peer(port)
  end
  render_state
end

# @param blockchain
# @param peers
post '/gossip' do
  their_blockchain = YAML.load(params['blockchain'])
  their_peers = YAML.load(params['peers'])
  update_blockchain(their_blockchain)
  update_peers(their_peers)
  YAML.dump('peers' => $PEERS, 'blockchain' => $BLOCKCHAIN)
end

# @param to (port_number)
# @param amount
post '/send_money' do
  to = Client.get_pub_key(params['to'])
  amount = params['amount'].to_i
  $BLOCKCHAIN.add_to_chain(Transaction.new(PUB_KEY, to, amount, PRIV_KEY))
  'OK. Block mined!'
end

get '/pub_key' do
  PUB_KEY
end
