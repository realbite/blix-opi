require 'rubygems'
require 'rake'

Gem::Specification.new do |spec|
  spec.name = 'blix-opi'
  spec.version = '0.1.1'
  spec.author  = "Clive Andrews"
  spec.email   = "pacman@realitybites.nl"

  spec.platform = Gem::Platform::RUBY
  spec.summary = 'OPI Interface'
  spec.require_path = 'lib'

  spec.files = FileList['lib/**/*.rb'].to_a
  spec.extra_rdoc_files = ['README.md']

  spec.add_dependency('nokogiri', '>= 0.0.0')
end
