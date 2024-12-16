
Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-filter_automatic_redaction"
  spec.version       = "1.0.0"
  spec.authors       = ["Whitestack"]
  spec.email         = ["development@whitestack.com"]

  spec.summary       = "A simple fluent plugin for logs redaction."
  spec.description   = "A simple fluent plugin for logs redaction."
  spec.homepage      = "https://www.whitestack.com"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/whitestack/fluent-plugin-filter_automatic_redaction/blob/main"

  spec.require_paths = ["lib"]
  spec.add_runtime_dependency     'fluentd'
  spec.add_development_dependency 'test-unit'
end
