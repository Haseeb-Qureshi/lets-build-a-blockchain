require 'digest'

NUM_ZEROES = 4

def hash(message)
  Digest::SHA256.hexdigest(message)
end

def find_nonce(message)
  nonce = "HELP I'M TRAPPED IN A NONCE FACTORY"
  count = 0
  until is_valid_nonce?(nonce, message)
    nonce = nonce.next
    count += 1
  end
  puts count
  nonce
end

def is_valid_nonce?(nonce, message)
  hash(message + nonce).start_with?("0" * NUM_ZEROES)
end
