require 'rubygems'
require 'rake'
require 'bundler'

Dir.glob('lib/tasks/*.rake').each { |r| import r }

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
end

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end

require 'spec/rake/verify_rcov'
RCov::VerifyTask.new(:verify_rcov => ['clean', 'rcov']) do |t|
  t.threshold = 66.92
  t.index_html = 'coverage/index.html'
end

task :spec => :check_dependencies

task :default => [:clean, :verify_rcov, :doc]

task :release do
  version = ''
  IO.foreach('lyber-core.gemspec') do |line|
    if(line =~ /s.version.*=.*"(.*)"/)
      version = $1 
      break
    end
  end
  
  if(version == '')
    puts 'Unable to find version number in lyber-core.gemspec...Aborting release'
    exit 1
  end
  
  puts "Make sure:"
  puts "  1) Version #{version} of lyber-core has not been tagged and released previously"
  puts "  2) All of the tests pass"
  puts "Type yes to continue if all of these statements are true"
  
  resp = STDIN.gets.chomp
  unless(resp =~ /yes/ )
    puts "!!!!!!!!!Aborting release!!!!!!!!!!!"
    puts "\nPlease change the value of s.version in the lyber-core.gemspec file and make sure all tests pass"
    exit 1
  end
  
  puts "Releasing version #{version} of lyber-core gem"
  
  puts "  Tagging release"
  success = system "git tag -a v#{version} -m 'Gem version #{version}'"
  unless(success)
    puts "Failed to tag release. Aborting"
    exit 1
  end
  
  success = system "git push origin --tags"
  unless(success)
    puts "Failed to push tags to AFS.  Aborting"
    exit 1
  end
  
  puts "  Building gem"
  success = system "gem build lyber-core.gemspec"
  unless(success)
    puts "Failed to build gem.  Aborting"
    exit 1
  end
  
  puts "  Publishing gem to sulair-rails-dev DLSS gemserver"
  success = system "scp lyber-core-#{version}.gem webteam@sulair-rails-dev.stanford.edu:/var/www/html/gems"
  unless(success)
    puts "Failed to copy gem to sulair-rails-dev.  Aborting"
    FileUtils.rm("lyber-core-#{version}.gem")
    exit 1
  end
  
  success = system "ssh webteam@sulair-rails-dev.stanford.edu gem generate_index -d /var/www/html"
  unless(success)
    puts "Failed to regenerate gem index on sulair-rails-dev.  Aborting"
    FileUtils.rm("lyber-core-#{version}.gem")
    exit 1
  end
  
  puts "\n  Done!!!!!  A local copy of the gem is located in the pkg directory"
  FileUtils.mkdir("pkg") unless File.exists?("pkg")
  FileUtils.mv("lyber-core-#{version}.gem", "pkg")
  
end

