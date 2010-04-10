# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{lyber-core}
  s.version = "0.7.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Willy Mene"]
  s.date = %q{2010-04-09}
  s.description = %q{Contains classes to make http connections with a client-cert, use Jhove, and call Suri
Also contains core classes to build robots}
  s.email = %q{wmene@stanford.edu}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/catalog_service.rb",
     "lib/dor/base.rb",
     "lib/dor/suri_service.rb",
     "lib/dor/workflow_service.rb",
     "lib/dor_service.rb",
     "lib/file_utilities.rb",
     "lib/lyber_core.rb",
     "lib/lyber_core/connection.rb",
     "lib/lyber_core/robot.rb",
     "lib/lyber_core/work_item.rb",
     "lib/lyber_core/work_queue.rb",
     "lib/lyber_core/workflow.rb",
     "lib/lyber_core/workspace.rb",
     "lib/roxml_models/identity_metadata/dublin_core.rb",
     "lib/roxml_models/identity_metadata/identity_metadata.rb",
     "lyber-core.gemspec",
     "spec/certs/dummy.crt",
     "spec/certs/dummy.key",
     "spec/dor/base_spec.rb",
     "spec/dor/suri_service_spec.rb",
     "spec/dor/workflow_servce_spec.rb",
     "spec/lyber_core/connection_spec.rb",
     "spec/lyber_core/robot_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb",
     "test/test_data/100.txt",
     "test/test_data/2-3.txt",
     "test/test_data/3-4.txt",
     "test/test_data/4-5.txt",
     "test/test_data/DS-DublinCore",
     "test/test_data/DS-MODS-big.txt",
     "test/test_data/DS-MODS-small.txt",
     "test/test_data/DublinCoreChimera.xml",
     "test/test_data/IdentityMetadata-after.xml",
     "test/test_data/IdentityMetadata-before.xml",
     "test/test_data/Register",
     "test/test_data/Register.new",
     "test/test_data/RegisterRest.new",
     "test/test_data/add.txt",
     "test/test_data/barcode_catkey_map.txt",
     "test/test_data/bigadd.txt",
     "test/test_data/dc-small.xml",
     "test/test_data/error_catkeys.txt",
     "test/test_helper.rb",
     "test/unit/test_identity_metadata.rb"
  ]
  s.homepage = %q{http://github.com/wmene/lyber-core}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Core services used by the SULAIR Digital Library}
  s.test_files = [
    "spec/dor/base_spec.rb",
     "spec/dor/suri_service_spec.rb",
     "spec/dor/workflow_servce_spec.rb",
     "spec/lyber_core/connection_spec.rb",
     "spec/lyber_core/robot_spec.rb",
     "spec/spec_helper.rb",
     "test/test_helper.rb",
     "test/unit/test_identity_metadata.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<active-fedora>, [">= 1.0.7"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<active-fedora>, [">= 1.0.7"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<active-fedora>, [">= 1.0.7"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

