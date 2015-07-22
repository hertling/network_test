require 'csv'

class ResultRecorder
  def self.sanitize_filename(filename)
    # source: http://stackoverflow.com/a/10823131/3961937

    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    return fn.join '.'
  end

  def self.filename(options, r)
    sanitize_filename "#{options[:local_name]}-to-#{r[:remote_name]}.csv"
  end

  def self.record (options, result)
    column_header = ["time", "latency", "throughput up", "throughput down", "transmitted_dropped", "received_dropped"]
    write_headers=true

    fname=filename(options, result)
    write_headers=false if File.exists?(fname)

    CSV.open(fname, "a+",
               :write_headers => write_headers,
               :headers => column_header) do |hdr|
      column_header=nil #No header after first insertion
      data_out = [result[:time],
                  result[:latency].round(4),
                  result[:throughput_up].round(4),
                  result[:throughput_down].round(4),
                  result[:transmitted_dropped],
                  result[:received_dropped]]
      hdr << data_out
    end

  end

end