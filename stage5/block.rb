require 'colorize'
require 'digest'

class Block
  NUM_ZEROES = 4
  attr_reader :own_hash, :prev_block_hash

  def initialize(prev_block, msg)
    @msg = msg
    @prev_block_hash = prev_block.own_hash if prev_block
    mine_block!
  end

  def mine_block!
    @nonce = calc_nonce
    @own_hash = hash(full_block(@nonce))
  end

  def valid?
    is_valid_nonce?(@nonce)
  end

  def to_s
    [
      "",
      "-" * 80,
      "Previous hash: ".rjust(15) + @prev_block_hash.to_s.yellow,
      "Message: ".rjust(15) + @msg.green,
      "Nonce: ".rjust(15) + @nonce.red,
      "Own hash: ".rjust(15) + @own_hash.yellow,
      "-" * 80,
      "|".rjust(40),
      "|".rjust(40),
      "↓".rjust(40),
    ].join("\n")
  end

  private

  def hash(contents)
    Digest::SHA256.hexdigest(contents)
  end

  def calc_nonce
    nonce = "HELP I'M TRAPPED IN A NONCE FACTORY"
    count = 0
    until is_valid_nonce?(nonce)
      print "." if count % 100_000 == 0
      nonce = nonce.next
      count += 1
    end
    nonce
  end

  def is_valid_nonce?(nonce)
    hash(full_block(nonce)).start_with?("0" * NUM_ZEROES)
  end

  def full_block(nonce)
    [@msg, @prev_block_hash, nonce].compact.join
  end
end

class BlockChain
  attr_reader :blocks

  def initialize(msg)
    @blocks = []
    @blocks << Block.new(nil, msg)
  end

  def add_to_chain(msg)
    @blocks << Block.new(@blocks.last, msg)
    puts @blocks.last
  end

  def valid?
    @blocks.all? { |block| block.is_a?(Block) } &&
      @blocks.all?(&:valid?) &&
      @blocks.each_cons(2).all? { |a, b| a.own_hash == b.prev_block_hash }
  end

  def to_s
    @blocks.map(&:to_s).join("\n")
  end
end

b = BlockChain.new("Genesis Block")
b.add_to_chain("Cinderella")
b.add_to_chain("The Three Stooges")
b.add_to_chain("Snow White")
