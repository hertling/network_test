require 'optparse'
require 'yaml'
require 'socket'


# 1. get parameters
#     set endpoint name
# 1. get parameters
#      set endpoint name (e.g. "Portland" or "SanDiego")
#      get remote address
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: server.rb [options]"

  opts.on('-n NAME', '--name NAME', 'Name of endpoint, e.g. "Portland"') { |v| options[:local_name] = v }

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

puts "Specified options:"
puts options.to_yaml
puts "\n"

puts "Missing required -n NAME argument. See --help" unless options[:local_name]

puts "Starting test slave for #{options[:local_name]}"

def receive_packets(n)
  packets_received=0

  BasicSocket.do_not_reverse_lookup = true
  client = UDPSocket.new
  client.bind('0.0.0.0', 6364)

  # keep receiving packets until we go 5 seconds without receiving one.

  while IO.select([client], nil, nil, 5)
    data, addr = client.recvfrom(1024)
    packets_received+=1
  end

  client.close

  packets_received
end

# Slave

# Open TCP port
# Loop forever
#   read line
server = TCPServer.new 6363

SIZE = 1024 * 1024 * 5

loop do
  client = server.accept    # Wait for a client to connect
  puts "Client connected at #{Time.now}"
  test_run=:started

  while test_run==:started
    command = client.gets
    command = command.strip unless command.nil?

    puts "received '#{command}'"
    case command
      when 'NAME'
        client.puts options[:local_name]

      when 'PING'
        client.puts 'ACK'

      when 'PACKETDROP'
        target_packets = client.gets.strip.to_i
        num_received = receive_packets(target_packets)
        client.puts "#{num_received}:#{target_packets}"

      when 'FINISHED'
        test_run=:finished
        puts "test run finished.\ncurrent memory usage: #{`ps -o rss -p #{$$}`.strip.split.last.to_i} KB\n"
        client.close

      when 'Start throughput test'
        throughput_server = TCPServer.new 6364
        throughput_client = throughput_server.accept

        bytes_received=0
        start_time = Time.now
        while chunk = throughput_client.read(SIZE)
          bytes_received+=chunk.size
        end
        throughput_client.close

        elapsed_time = Time.now - start_time
        client.puts elapsed_time

      when 'EXIT'
        exit

      when nil
        puts "  client closed connection without sending FINISHED. cleaning up."
        test_run=:finished
        client.close

      else
        puts "UNKNOWN COMMAND: #{command}"
    end
  end

end

# if THROUGHPUT X
#   read X bytes
#   send X bytes

# if PACKETDROP X
#   open udp port
#   listen
#     count packets received
#     at X or 1 minute, quit
#   send "y:X"
#   send X udp packets

# if PACKETDROP DONE
#   close udp ports

# if FINISHED
#   exit

