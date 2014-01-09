require 'rake'

Gem::Specification.new do |s|
  s.name        = 'js_base'
  s.version     = '0.0.3'
  s.date        = '2013-12-04'
  s.summary     = "Jeff's basic Ruby utility functions"
  s.description = "Some fundamental functions, plus some testing utilities"
  s.authors     = ["Jeff Sember"]
  s.email       = 'jpsember@gmail.com'
  s.files = FileList['lib/**/*.rb',
                      'bin/*',
                      '[A-Z]*',
                      'test/**/*',
                      ]
  s.homepage = 'http://www.cs.ubc.ca/~jpsember'
  s.test_files  = Dir.glob('test/*.rb')
  s.license     = 'MIT'
end

