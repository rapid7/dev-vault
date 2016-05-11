require_relative './lib/dev/vault/build'

## On interupt, wait fot the Vault process to shutdown
Signal.trap('INT') do
  Dev::Vault.stop
end

task :fetch do
  Dev::Vault::Build.fetch
end

task :run do
  Dev::Vault.run
end

task :wait do
  Dev::Vault.wait
end

task :default => [:run, :wait]
