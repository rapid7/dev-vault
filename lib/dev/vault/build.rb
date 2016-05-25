require_relative '../vault'

require 'net/http'
require 'uri'

begin
  require 'zipruby'
rescue LoadError
  puts 'To use Dev::Vault::Build, you must install the zipruby gem!'
end

module Dev
  class Vault
    ##
    # Tools to fetch and extract Hashicorp's platform builds of Vault
    ##
    module Build
      REPOSITORY = "https://releases.hashicorp.com/vault/#{VERSION}".freeze
      PACKAGES = [
        "vault_#{VERSION}_darwin_386.zip",
        "vault_#{VERSION}_darwin_amd64.zip",
        "vault_#{VERSION}_freebsd_386.zip",
        "vault_#{VERSION}_freebsd_amd64.zip",
        "vault_#{VERSION}_freebsd_arm.zip",
        "vault_#{VERSION}_linux_386.zip",
        "vault_#{VERSION}_linux_amd64.zip",
        "vault_#{VERSION}_linux_arm.zip"
      ].freeze

      class << self
        def fetch
          uri = URI.parse(REPOSITORY)
          client = Net::HTTP.new(uri.host, uri.port)
          client.use_ssl = true if uri.scheme == 'https'

          PACKAGES.each do |package|
            puts "Fetch #{File.join(uri.path, package)}"
            request = Net::HTTP::Get.new(File.join(uri.path, package))

            client.request(request) do |response|
              Zip::Archive.open_buffer(response.body) do |archive|
                archive.each do |file|
                  next unless file.name == 'vault'

                  open(File.join(Vault.bindir, File.basename(package, '.zip')), 'wb', 00755) { |io| io.write(file.read) }
                end
              end
            end
          end
        end
      end
    end
  end
end
