require 'faraday'

class Client
  URL = 'http://localhost'

  def self.gossip(port, state)
    return JSON.dump({}) if port == PORT
    begin
      Faraday.post("#{URL}:#{port}/gossip", state: state).body
    rescue Faraday::ConnectionFailed => e
      raise
    end
  end
end
