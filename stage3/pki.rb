require 'openssl'
require 'base64'

def generate_key_pair
  key_pair = OpenSSL::PKey::RSA.new(2048)
  private_key, public_key = key_pair.export, key_pair.public_key.export
end

def sign(plaintext, raw_private_key)
  private_key = OpenSSL::PKey::RSA.new(raw_private_key)
  Base64.encode64(private_key.private_encrypt(plaintext))
end

def plaintext(ciphertext, raw_public_key)
  public_key = OpenSSL::PKey::RSA.new(raw_public_key)
  public_key.public_decrypt(Base64.decode64(ciphertext))
end

def valid_signature?(message, ciphertext, public_key)
  message == plaintext(ciphertext, public_key)
end
