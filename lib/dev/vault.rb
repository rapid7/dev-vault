require_relative './vault/version'
require_relative './vault/helpers'

require 'json'
require 'securerandom'
require 'tempfile'
require 'vault'

module Dev
  ##
  # Helpers to fetch and run a development-instance of vault
  ##
  class Vault
    extend Helpers

    DEFAULT_PORT = 8200
    RANDOM_PORT = 'RANDOM_PORT'.freeze

    attr_reader :command
    attr_reader :config
    attr_reader :output

    attr_reader :dev
    alias_method :dev?, :dev

    attr_reader :client
    attr_reader :port

    attr_reader :keys
    attr_reader :token

    def initialize(**options)
      @dev = options.fetch(:dev, true)
      @token = dev ? SecureRandom.uuid : options[:token]

      @port = case options[:port]
              when Fixnum then options[:port]
              when RANDOM_PORT then 10_000 + rand(10_000)
              else DEFAULT_PORT
              end

      @command = [self.class.bin, 'server']
      @command.push(*['-dev', "-dev-root-token-id=#{token}", "-dev-listen-address=127.0.0.1:#{port}"]) if dev?
      @output = options.fetch(:output, $stdout)

      ## Non-development mode server
      unless dev?
        @config = Tempfile.new('dev-vault')
        @command << "-config=#{config.path}"
      end

      @client = ::Vault::Client.new(:address => "http://localhost:#{port}",
                                    :token => token)
    end

    ## Logging helper
    def log(*message)
      return unless output.is_a?(IO)

      output.write(message.join(' ') + "\n")
      output.flush
    end

    ##
    # Write configuration to tempfile
    ##
    def configure
      raise 'Cannot configure a Vault server in development mode' if dev?

      config.write(
        JSON.pretty_generate(
          :backend => {
            :inmem => {}
          },
          :listener => {
            :tcp => {
              :address => "127.0.0.1:#{port}",
              :tls_disable => 'true'
            }
          }
        )
      )

      config.rewind
    end

    ##
    # Helper to initialize a non-development Vault server and store the new token
    ##
    def init(**options)
      raise 'Cannot initialize a Vault server in development mode' if dev?

      options[:shares] ||= 1
      options[:threshold] ||= 1

      result = client.sys.init(options)

      ## Capture the new keys and token
      @keys = result.keys
      @token = result.root_token
    end

    def run
      configure unless dev?
      log "Running #{command.join(' ')}"

      ## Fork a child process for Vault from a thread
      @stopped = false
      @thread = Thread.new do
        IO.popen(command + [:err => [:child, :out]], 'r+') do |io|
          Thread.current[:process] = io.pid

          ## Stream output
          loop do
            break if io.eof?
            chunk = io.readpartial(1024)

            next unless output.is_a?(IO)
            output.write(chunk)
            output.flush
          end
        end
      end

      self
    end

    ##
    # Wait for the service to become ready
    ##
    def wait
      loop do
        break if @stopped || @thread.nil? || !@thread.alive?

        begin
          client.sys.init_status
        rescue ::Vault::HTTPConnectionError
          log 'Waiting for Vault HTTP API to be ready'
          sleep 1

          next
        end

        if dev? && !client.sys.init_status.initialized?
          log 'Waiting for Vault development server to initialize'
          sleep 1

          next
        end

        log 'Vault is ready!'
        break
      end

      self
    end

    def block
      @thread.join unless @thread.nil?
    end

    def stop
      unless @thread.nil?
        unless @thread[:process].nil?
          log "Stop #{command.join(' ')} (#{@thread[:process]})"
          Process.kill('TERM', @thread[:process])
        end

        @thread.join
      end

      config.unlink unless dev?
      @thread = nil
      @stopped = true
    end
  end
end
