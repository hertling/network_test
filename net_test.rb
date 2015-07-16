require 'optparse'
require 'yaml'
require 'socket'

# 1. get parameters
#     set endpoint name (e.g. "Portland" or "SanDiego")
#     get remote address
#     get frequency of test from parameters (default = 15 minutes)
#     get duration of test (default = 2 hours)
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: net_test.rb [options]"

  opts.on('-n NAME', '--name NAME', 'Name of endpoint, e.g. "Portland"') { |v| options[:local_name] = v }
  opts.on('-r HOST', '--remote HOST', 'Remote hostname or IP address') { |v| options[:host] = v }
  opts.on('-i INTERVAL', '--interval INTERVAL', 'Interval in minutes to run test') { |v| options[:interval] = v.to_f }
  opts.on('-d DURATION', '--duration DURATION', 'How long in hours to run test') { |v| options[:duration] = v.to_f }
  opts.on('-p PACKETS', '--packets PACKETS', 'How long in hours to run test') { |v| options[:packets] = v.to_i }

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

end.parse!

puts "Missing required -n NAME argument. See --help" unless options[:local_name]
puts "Missing required -r HOST argument. See --help" unless options[:host]
options[:interval]=15 unless options[:interval]
options[:duration]=2 unless options[:duration]
options[:packets]=1000 unless options[:packets]

puts "Settings:"
puts options.to_yaml
puts "\n"

launch_time = Time.now
keep_running_until = launch_time + (options[:duration]*60*60)
puts "This test will keep running until #{keep_running_until}"


# m4. ping test
def ping(s)
  start_time = Time.now
  s.puts 'PING'
  s.gets
  elapsed = (Time.now - start_time) * 1000
  elapsed
end


def latency(s)
  results = []
  3.times do
    results << ping(s)
  end
  results.max
end


# m6. packet drop test part 2

#        open udp socket
#        listen for packets and count them for at most one minute
#        close udp socket
#        send "PACKETDROP DONE"
#        close tcp socket
#        result = percent of up packets dropped, percent down packets dropped

def send_packets(options)
  u = UDPSocket.new
  u.connect(options[:host], 6364)
  start_time = Time.now
  options[:packets].times do |i|
    u.send "p#{i}", 0
  end
  elapsed_time = Time.now - start_time
  u.close

  puts "    sent #{options[:packets]} packets in #{(elapsed_time*1000).round(2)} ms"
end

def packet_drop_test(options, s)
  puts "  Starting packet test with #{options[:packets]} packets"
  s.puts "PACKETDROP"
  s.puts options[:packets]
  sleep 1
  send_packets(options)
  sleep 1
  reply = s.gets
  puts "    reply: #{reply}"
  puts "    finished packet drop test"
  received, expected = reply.split(':')
  up_success_ratio = received.to_i / expected.to_i
  [up_success_ratio, 0.0]
end


def run_suite(options, run_number)
# start run
  puts "\n\nStarting run #{run_number}!"
  s = TCPSocket.new options[:host], 6363
  test_run={}


  # m1.5. get remote name
  s.puts 'NAME'
  remote_name = s.gets
  puts "  #{options[:local_name]} --> #{remote_name}"


  # m2. execute needed tests
  $interval_start_time = Time.now

  # m3. latency test: do ping test 3 times, take slowest score.
  test_run[:latency] = latency(s)
  puts "  Latency test result (worst of 3): #{test_run[:latency].round(3)} ms"


# m5. throughput test
#        open tcp socket
#        Send "THROUGHPUT 5*1024*1024"
#        start_send_time
#        send 5 MB
#        end_send_time
#        start_receive_time
#        receive 5 MB
#        end_receive_time
#        result = up speed in mbps, down speed in mbps
#        close tcp socket

  test_run[:up_success_ratio], test_run[:down_success_ratio] = packet_drop_test(options, s)
  puts "  Packet Drop Test (ratio of 1000 packets transmitted):"
  puts "    Up   ratio: #{test_run[:up_success_ratio].round(4)}"
  puts "    Down ratio: #{test_run[:down_success_ratio].round(4)}"



# m7. log data
#        if logfile doesn't exist, create it and header
#        write remote name, time, latency, throughput, packet drop
#        close log file

# m8. sleep until next interval
#        interval start time + interval time = next run time
#        if next_interval after end_time, clean up.

  s.puts "FINISHED"
  s.close             # close socket when done
end


run_number=0

until Time.now > keep_running_until
  run_suite(options, run_number+=1)

  time_until_next_run = ($interval_start_time + (options[:interval]*60)) - Time.now
  puts "\nNext run is in #{time_until_next_run.round(2)} seconds, or #{(time_until_next_run/60.0).round(2)} minutes"

  test_time_left = keep_running_until - Time.now
  puts "Test will keep running for #{(test_time_left/60.0).round(2)} minutes, or #{(test_time_left/3600.0).round(2)} hours"
  puts "NETWORK TESTING IN PROGRESS. DO NOT KILL OR TURN OFF MACHINE.\nSleeping..."

  sleep time_until_next_run
end

# m9. clean up
#        send "EXIT" to remove end
#        email log file to interested parties


