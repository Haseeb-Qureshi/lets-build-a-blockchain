require 'sinatra'
require 'colorize'

BALANCES = {
  'haseeb' => 100_000,
}

def print_state
  puts BALANCES.to_s.green
end

# @param user
get "/balance" do
  username = params['user'].downcase
  print_state
  "#{username} has #{BALANCES[username]}"
end

# @param name
post "/users" do
  name = params['name'].downcase
  BALANCES[name] ||= 0
  print_state
  "OK"
end

# @param from
# @param to
# @param amount
post "/transfers" do
  from, to = params.values_at('from', 'to').map(&:downcase)
  amount = params['amount'].to_i
  raise InsufficientFunds if BALANCES[from] < amount
  BALANCES[from] -= amount
  BALANCES[to] += amount
  print_state
  "OK"
end

class InsufficientFunds < StandardError; end
