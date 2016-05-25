Dev::Vault
===========

`Dev::Vault` is a simple wrapper around the Vault binary for development and testing. It bundles all of the published Vault binaries at `Dev::Vault::VERSION` and runs the correct build for the local system.

Note that `Dev::Vault`'s version follows that of Vault.

Vault is maintained by Hashicorp. Please see https://www.vaultproject.io/ for details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dev-vault'
```

Or Gemspec:

```ruby
spec.add_development_dependency 'dev-vault', '0.6.4'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install dev-vault

## Usage

Run `bundle exec rake` to launch a local instance of Vault.

To integrate into tests:

```ruby
require 'dev/vault'

RSpec.configure do |config|
  config.before(:suite) do
    ## Start Vault with logging suppressed
    Dev::Vault.run(:output => false)
  end

  config.after(:suite) do
    Dev::Vault.stop
  end

  ## ...
end
```

For more advanced test scenarios involving `init`, `seal`, and `unseal` operations, start a non-dev Vault instance with the `inmem` storage provider:

```ruby
require 'dev/vault'

RSpec.describe 'Some Vault Test'
  subject(:vault) do
    Dev::Vault.new(
      :dev => false,
      :port => Dev::Vault::RANDOM_PORT,
      :output => false
    ).run.wait
  end

  after { vault.stop }

  it 'initializes vault' do
    vault.client.sys.init

    expect(vault.client.sys.init_status.initialized?).to be true
  end
```

This test suite will create and destroy un-initialized vault instances for each case.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rapid7/dev-vault.
