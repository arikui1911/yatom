# frozen_string_literal: true

require_relative "lib/yatom/version"

Gem::Specification.new do |spec|
  spec.name          = "yatom"
  spec.version       = Yatom::VERSION
  spec.authors       = ["arikui1911"]
  spec.email         = ["arikui.ruby@gmail.com"]

  spec.summary       = "Yet another TOML parser"
  spec.description   = "It is TOML parser and generates Ruby object from parsed result."
  spec.homepage      = "https://github.com/arikui1911/yatom"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/arikui1911/yatom"
  spec.metadata["changelog_uri"] = "https://github.com/arikui1911/yatom/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'rspec-parameterized'

end
