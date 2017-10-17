require 'colorize'
require 'digest'
require_relative 'pki'

class Block
  NUM_ZEROES = 4
  attr_reader :own_hash, :prev_block_hash, :txn

  def self.create_genesis_block(pub_key, priv_key)
    genesis_txn = Transaction.new(nil, pub_key, 500_000, priv_key)
    Block.new(nil, genesis_txn)
  end

  def initialize(prev_block, txn)
    raise TypeError unless txn.is_a?(Transaction)
    @txn = txn
    @prev_block_hash = prev_block.own_hash if prev_block
    mine_block!
  end

  def mine_block!
    @nonce = calc_nonce
    @own_hash = hash(full_block(@nonce))
  end

  def valid?
    is_valid_nonce?(@nonce) && @txn.is_valid_signature?
  end

  def to_s
    [
      "Previous hash: ".rjust(15) + @prev_block_hash.to_s.yellow,
      "Message: ".rjust(15) + @txn.to_s.green,
      "Nonce: ".rjust(15) + @nonce.light_blue,
      "Own hash: ".rjust(15) + @own_hash.yellow,
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
    [@txn.to_s, @prev_block_hash, nonce].compact.join
  end
end

class Transaction
  attr_reader :from, :to, :amount
  def initialize(from, to, amount, priv_key)
    @from = from
    @to = to
    @amount = amount
    @signature = PKI.sign(message, priv_key)
  end

  def is_valid_signature?
    return true if genesis_txn? # genesis transaction is always valid
    PKI.valid_signature?(message, @signature, from)
  end

  def genesis_txn?
    from.nil?
  end

  def message
    Digest::SHA256.hexdigest([@from, @to, @amount].join)
  end

  def to_s
    message
  end
end

class BlockChain
  attr_reader :blocks

  def initialize(originator_pub_key, originator_priv_key)
    @blocks = []
    @blocks << Block.create_genesis_block(originator_pub_key, originator_priv_key)
  end

  def length
    @blocks.length
  end

  def add_to_chain(txn)
    @blocks << Block.new(@blocks.last, txn)
  end

  def valid?
    @blocks.all? { |block| block.is_a?(Block) } &&
      @blocks.all?(&:valid?) &&
      @blocks.each_cons(2).all? { |a, b| a.own_hash == b.prev_block_hash } &&
      all_spends_valid?
  end

  def all_spends_valid?
    compute_balances do |balances, from, to|
      return false if balances.values_at(from, to).any? { |bal| bal < 0 }
    end
    true
  end

  def compute_balances
    genesis_txn = @blocks.first.txn
    balances = { genesis_txn.to => genesis_txn.amount }
    balances.default = 0 # New people automatically have balance of 0
    @blocks.drop(1).each do |block| # Ignore the genesis block
      from = block.txn.from
      to = block.txn.to
      amount = block.txn.amount

      balances[from] -= amount
      balances[to] += amount
      yield balances, from, to if block_given?
    end
    balances
  end

  def to_s
    @blocks.map(&:to_s).join("\n")
  end
end
