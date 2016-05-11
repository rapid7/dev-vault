require_relative './vault/version'

require 'json'
require 'net/http'
require 'securerandom'

module Dev
  ##
  # Helpers to fetch and run a development-instance of vault
  ##
  module Vault
    class << self
      def bindir
        File.expand_path('../../bin', __dir__)
      end

      def architecture
        case RUBY_PLATFORM
        when /x86_64/ then 'amd64'
        when /amd64/ then 'amd64'
        when /386/ then '386'
        when /arm/ then 'arm'
        else raise NameError, "Unable to detect system architecture for #{RUBY_PLATFORM}"
        end
      end

      def platform
        case RUBY_PLATFORM
        when /darwin/ then 'darwin'
        when /freebsd/ then 'freebsd'
        when /linux/ then 'linux'
        else raise NameError, "Unable to detect system platfrom for #{RUBY_PLATFORM}"
        end
      end

      def bin
        File.join(bindir, "vault_#{VERSION}_#{platform}_#{architecture}")
      end

      def token
        @token ||= SecureRandom.uuid
      end

      def mount(name)
        post = Net::HTTP::Post.new("/v1/sys/mounts/#{name}")
        post.body = JSON.generate(:type => name)
        post['X-Vault-Token'] = token

        Net::HTTP.new('localhost', 8200).request(post)
      end

      def output(arg = nil)
        @thread[:output] = arg unless @thread.nil? || arg.nil?
        @thread[:output] unless @thread.nil?
      end

      def run
        puts "Starting #{bin}"

        ## Fork a child process for Vault from a thread
        @thread = Thread.new do
          IO.popen(%(#{bin} server -dev -dev-root-token-id="#{token}"), 'r+') do |io|
            Thread.current[:process] = io.pid
            puts "Started #{bin} (#{io.pid})"

            ## Stream output
            loop do
              break if io.eof?
              chunk = io.readpartial(1024)

              if Thread.current[:output]
                Thread.current[:output].write(chunk)
                Thread.current[:output].flush
              end
            end
          end
        end

        @thread[:output] = $stdout

        ## Wait for the service to become ready
        loop do
          begin
            break if @stopped

            status = Net::HTTP.get('localhost', '/v1/sys/seal-status', 8200)
            status = JSON.parse(status, :symbolize_names => true)

            if status[:sealed]
              puts 'Waiting for Vault HTTP API to be ready'
              sleep 1

              next
            end

            puts 'Vault HTTP API is ready!'
            break

          rescue Errno::ECONNREFUSED, JSON::ParseError
            puts 'Waiting for Vault HTTP API to be ready'
            sleep 1
          end
        end
      end

      def wait
        @thread.join unless @thread.nil?
      end

      def stop
        unless @thread.nil?
          unless @thread[:process].nil?
            puts "Stop #{bin} (#{@thread[:process]})"
            Process.kill('INT', @thread[:process])
          end

          @thread.join
        end

        @thread = nil
        @stopped = true
      end
    end
  end
end
