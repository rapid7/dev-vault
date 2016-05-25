require_relative './lib/dev/vault/build'

## On interupt, wait fot the Vault process to shutdown
Signal.trap('INT') do
  Dev::Vault.stop
end

task :fetch do
  Dev::Vault::Build.fetch
end

task :dev do
  Dev::Vault.run
  Dev::Vault.wait
end

task :nodev do
  Dev::Vault.run(:dev => false, :port => Dev::Vault::RANDOM_PORT)
  Dev::Vault.wait
end

task :block do
  Dev::Vault.block
end

task :default => [:dev, :block]
