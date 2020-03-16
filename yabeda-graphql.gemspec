require_relative 'lib/yabeda/graphql/version'

Gem::Specification.new do |spec|
  spec.name          = "yabeda-graphql"
  spec.version       = Yabeda::GraphQL::VERSION
  spec.authors       = ["Andrey Novikov"]
  spec.email         = ["envek@envek.name"]

  spec.summary       = %q{Collects metrics to monitor execution of your GraphQL queries}
  spec.description   = %q{Extends Yabeda metrics with graphql-ruby metrics: queries, mutations, fields…}
  spec.homepage      = "http://github.com/yabeda-rb/yabeda-graphql"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "yabeda",  "~> 0.2"
  spec.add_runtime_dependency "graphql", "~> 1.9"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
