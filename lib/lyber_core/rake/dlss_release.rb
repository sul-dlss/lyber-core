require 'rake/tasklib'
require 'pony'

module LyberCore

  # A rake task that will tag, build and publish your gem to the DLSS gemserver
  # 
  # == Usage
  # Include the following two lines in your <tt>Rakefile</tt>:
  #   require 'lyber_core/rake/dlss_release'
  #   LyberCore::DlssRelease.new
  # 
  # To build and release the gem, run the following:
  #   rake dlss_release
  #
  # == Requirements
  # - You need <b>ONE</b> <tt>your-gemname.gemspec</tt> file in the root of your project. See the example in <tt>lyber-core.gemspec</tt> or look at http://yehudakatz.com/2010/04/02/using-gemspecs-as-intended/
  # - Inside the <tt>Gem::Specification</tt> block of the <tt>your-gemname.gemspec</tt> file, you must set the version number.  For example
  #     Gem::Specification.new do |s|
  #       s.name        = "your-gemname"
  #       ...
  #       s.version     = "0.9.6"
  #       ...
  #     end
  # - You need to have access to the account on the DLSS gemserver, usually by adding your sunetid to the .k5login.  You also need git installed.
  class DlssRelease < Rake::TaskLib
    # Name of the rake task. Defaults to :dlss_release
    attr_accessor :name
    
    # Name of the gem
    attr_accessor :gemname
    
    # Version of the gem being released
    attr_accessor :version
    
    def initialize(name=:dlss_release)
      @name = name
      @gemname = determine_gemname
      yield self if block_given?
      raise "Gemname must be set" if @gemname.nil?
      define
    end
    
    # Tries to parse the gemname from the prefix of the <tt>your-gemname.gemspec</tt> file.
    def determine_gemname
      files = Dir.glob("*.gemspec")
      raise "Unable to find project gemspec file.\nEither it doesn't exist or there are too many files ending in .gemspec" if(files.size != 1)
      
      files.first =~ /(.*)\.gemspec/
      $1
    end
    
    def send_release_announcement
      Pony.mail(:to => 'dlss-developers@lists.stanford.edu', 
                :from => 'dlss-developers@lists.stanford.edu', 
                :subject => "Release #{@version} of the #{@gemname} gem", 
                :body => "The #{@gemname}-#{@version}.gem has been released to the DLSS gemserver", 
                :via => :smtp, 
                :via_options => {
                  :address        => 'smtp.stanford.edu',
                  :port           => '25',
                  :enable_starttls_auto => true,
                  :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
                  :domain         => "localhost.localdomain" # the HELO domain provided by the client to the server
                }
      )
    end
    
    def define
      desc "Tag, build, and release DLSS specified gem"
      task @name do
        IO.foreach(File.join(Rake.original_dir, "#{@gemname}.gemspec")) do |line|
          if(line =~ /\.version.*=.*"(.*)"/)
            @version = $1 
            break
          end
        end

        if(@version.nil?)
          raise "Unable to find version number in #{@gemname}.gemspec"
        end
        created_gem = "#{@gemname}-#{@version}.gem"

        puts "Make sure:"
        puts "  1) Version #{@version} of #{@gemname} has not been tagged and released previously"
        puts "  2) All of the tests pass"
        puts "Type 'yes' to continue if all of these statements are true"

        resp = STDIN.gets.chomp
        unless(resp =~ /yes/ )
          raise "\nPlease change the value of s.version in the #{@gemname}.gemspec file and make sure all tests pass"
        end

        puts "Releasing version #{@version} of the #{@gemname} gem"
        
        begin
          puts "...Tagging release"
          sh "git tag -a v#{@version} -m 'Gem version #{@version}'"
          sh "git push origin --tags"

          puts "...Building gem"
          sh "gem build #{@gemname}.gemspec"

          puts "...Publishing gem to sulair-rails-dev DLSS gemserver" 
          sh "scp #{created_gem} webteam@sulair-rails-dev.stanford.edu:/var/www/html/gems"
          sh "ssh webteam@sulair-rails-dev.stanford.edu gem generate_index -d /var/www/html"

          puts "Done!!!!!  A local copy of the gem is in the pkg directory"
          FileUtils.mkdir("pkg") unless File.exists?("pkg")
          FileUtils.mv("#{created_gem}", "pkg")
        rescue Exception => e
          FileUtils.rm("#{created_gem}") if(File.exists?("#{created_gem}"))
          raise e
        end
      
        puts "Sending release announcement to DLSS developers list"
        send_release_announcement
        
      end
    end
  end
end