require 'csv'

class ResultRecorder
  def sanitize_filename(filename)
    # source: http://stackoverflow.com/a/10823131/3961937

    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    return fn.join '.'
  end

  def initialize(options)
    @options=options
  end

  def filename(r)
    sanitize_filename "#{@options[:local_name]}-to-#{r[:remote_name]}.csv"
  end

  def add_row(result)
    column_header = ["time", "ping", "throughput up", "throughput down", "packetdrop up", "packetdrop down"]

    CSV.open(filename(result), "a+",
               :write_headers => true,
               :headers => column_header) do |hdr|
      column_header=nil #No header after first insertion
      data_out = [result[:time],
                  result[:ping],
                  result[:throughput_up],
                  result[:throughput_down],
                  result[:packetdrop_up],
                  result[:packetdrop_down]]
      hdr << data_out
    end

  end

end