require 'forwardable'

module Dev
  class Vault
    ##
    # Helpers to fetch and run a development-instance of vault
    ##
    module Helpers
      extend Forwardable

      def bindir
        File.expand_path('../../../bin', __dir__)
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

      def run(**options)
        @vault ||= Vault.new(options).run
      end

      def_delegators :@vault, :client, :command, :config, :dev, :dev?, :port, :token, :output, :configure, :init, :wait, :block, :stop
    end
  end
end
