# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aion_cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'aion_cli'
  spec.version       = AionCLI::VERSION
  spec.authors       = ['Michael Andersen']
  spec.email         = ['michael.andersen.85@gmail.com']

  spec.summary       = %q{A small collection of scripts used by Aion Aps}
  spec.description   = %q{A small collection of scripts used by Aion Aps. Mainly for handling csv files.}
  spec.homepage      = 'https://github.com/aion-dk/aion_cli'

  spec.license       = 'Aion'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://gems.valgservice.dk'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0.20.3'
  spec.add_dependency 'charlock_holmes', '~> 0.7.6'
  spec.add_dependency 'roo', '~> 2.7.1'
  spec.add_dependency 'faker', '~> 1.9.1'
  spec.add_dependency 'httpclient', '~> 2.8.3'
  spec.add_dependency 'write_xlsx', '~> 0.85.5'
  spec.add_dependency 'activesupport', '~> 5.2.1'
  #spec.add_dependency 'aion-s3', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 1.17.1'
  spec.add_development_dependency 'rake', '~> 12.3.1'
  spec.add_development_dependency 'minitest', '~> 5.11.3'
end
