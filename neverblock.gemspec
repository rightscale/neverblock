require 'rake'

Gem::Specification.new do |s|
  s.name     = "neverblock"
  s.version  = "1.1"
  s.date     = "2013-06-17"
  s.summary  = "Utilities for non-blocking stack components"
  s.email    = "support@rightscale.com"
  s.homepage = "http://github.com/rightscale/neverblock"
  s.description = "NeverBlock is a collection of classes and modules that help you write evented non-blocking applications in a seemingly blocking mannner."
  s.has_rdoc = true
  s.authors  = ["Muhammad A. Ali", "Ahmed Sobhi", "Osama Brekaa"]
  s.files    = FileList[
		"neverblock.gemspec",
		"README",
    "lib/**/*.rb"
  ]
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["README"]
  s.add_dependency('eventmachine', '>= 0.12.10')
end
