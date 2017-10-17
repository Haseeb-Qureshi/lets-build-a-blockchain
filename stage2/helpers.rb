Thread.abort_on_exception = true

def every(seconds)
  Thread.new do
    loop do
      sleep seconds
      yield
    end
  end
end

def render_state
  puts "-" * 40
  STATE.to_a.sort_by(&:first).each do |port, (movie, version_number)|
    puts "#{port.to_s.green} currently likes #{movie.yellow}"
  end
  puts "-" * 40
end

def update_state(update)
  update.each do |port, (movie, version_number)|
    next if port.nil?

    if [movie, version_number].any?(&:nil?)
      STATE[port] ||= nil
    else
      STATE[port] = [STATE[port], [movie, version_number]].compact.max_by(&:last)
    end
  end
end
