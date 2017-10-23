require 'sinatra'
require 'colorize'
require 'active_support/time'
require_relative 'client'
require_relative 'helpers'

PORT, PEER_PORT = ARGV.first(2)
set :port, PORT

STATE = ThreadSafe::Hash.new
update_state(PORT => nil)
update_state(PEER_PORT => nil)

MOVIES = File.readlines("movies.txt").map(&:chomp)
@favorite_movie = MOVIES.sample
@version_number = 0
puts "My favorite movie, now and forever, is #{@favorite_movie.green}!"

update_state(PORT => [@favorite_movie, @version_number])

every(8.seconds) do
  puts "Screw #{@favorite_movie.red}."
  @version_number += 1
  @favorite_movie = MOVIES.sample
  update_state(PORT => [@favorite_movie, @version_number])
  puts "My new favorite movie is #{@favorite_movie.green}!"
end

every(3.seconds) do
  STATE.keys.each do |port|
    next if port == PORT
    puts "Fetching update from #{port.to_s.green}"
    begin
      gossip_response = Client.gossip(port, JSON.dump(STATE))
      update_state(JSON.load(gossip_response))
    rescue Faraday::ConnectionFailed => e
      STATE.delete(port)
    end
  end
  render_state
end

# @param state
post '/gossip' do
  their_state = params[:state]
  update_state(JSON.load(their_state))
  JSON.dump(STATE)
end
