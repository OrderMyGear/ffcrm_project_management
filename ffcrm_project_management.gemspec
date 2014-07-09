$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ffcrm_project_management/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ffcrm_project_management"
  s.version     = FfcrmProjectManagement::VERSION
  s.authors     = ["Alex Eliseev"]
  s.email       = ["elja1989@gmail.com"]
  s.homepage    = ""
  s.summary     = "Adds project management to fat free crm"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_development_dependency 'pg'
  s.add_dependency 'fat_free_crm'
  s.add_dependency 'ffcrm_attachments'
end

