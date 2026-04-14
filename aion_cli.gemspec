lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aion_cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'aion_cli'
  spec.version       = AionCLI::VERSION
  spec.authors       = ['Michael Andersen']
  spec.email         = ['michael.andersen.85@gmail.com']

  spec.summary       = 'A small collection of scripts used by Aion Aps'
  spec.description   = 'A small collection of scripts used by Aion Aps. Mainly for handling csv files.'
  spec.homepage      = 'https://github.com/aion-dk/aion_cli'

  spec.license       = 'Aion'
  spec.required_ruby_version = '>= 3.2'

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

  spec.add_dependency 'activesupport', '~> 7.2'
  spec.add_dependency 'aion-s3', '~> 1.0'
  spec.add_dependency 'charlock_holmes', '~> 0.7.6'
  spec.add_dependency 'faker', '~> 3.6'
  spec.add_dependency 'http', '~> 5.0.4'
  spec.add_dependency 'roo', '~> 3.0'
  spec.add_dependency 'thor', '~> 1.4'
  spec.add_dependency 'write_xlsx', '~> 1.15'

  spec.add_development_dependency 'minitest', '~> 5.27'
  spec.add_development_dependency 'rake', '~> 13.3'
end
