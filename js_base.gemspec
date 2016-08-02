require 'rake'

Gem::Specification.new do |s|
  s.name        = File.basename(__FILE__,'.gemspec')
  s.version     = '1.1.13'
  s.date        = Time.now
  s.summary     = "Jeff's basic Ruby utility functions"
  s.description = "Some fundamental functions, plus some testing utilities"
  s.authors     = ["Jeff Sember"]
  s.email       = 'jpsember@gmail.com'
  s.files = FileList['lib/**/*.rb',
                      'bin/*',
                      '[A-Z]*',
                      'test/**/*',
                      ]
  s.add_runtime_dependency 'json', '~> 1.8', '>= 1.8.1'
  s.homepage = 'http://www.cs.ubc.ca/~jpsember'
  s.test_files  = Dir.glob('test/*.rb')
  s.license     = 'MIT'
end
