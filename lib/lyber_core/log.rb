
module LyberCore
  
  class LyberCore::Log
    require 'logger'
        
    # Default values
    DEFAULT_LOGFILE = "/tmp/lybercore_log.log"
    DEFAULT_LOG_LEVEL = 3
    DEFAULT_FORMATTER = proc{|s,t,p,m|"%5s [%s] (%s) %s :: %s\n" % [s, 
                       t.strftime("%Y-%m-%d %H:%M:%S"), $$, p, m]}
        
    # Initial state
    @@logfile = DEFAULT_LOGFILE
    @@log ||= Logger.new(@@logfile)
    # $stdout.reopen(@@logfile)
    # $stderr.reopen(@@logfile)
    @@log.level = DEFAULT_LOG_LEVEL
    @@log.formatter = DEFAULT_FORMATTER
    
    # Restore LyberCore::Log to its default state
    def Log.restore_defaults
      @@log.level = DEFAULT_LOG_LEVEL
      Log.set_logfile(DEFAULT_LOGFILE)
      @@log.formatter = DEFAULT_FORMATTER
    end
      
    # The current location of the logfile
    def Log.logfile
      return @@logfile
    end
    

    
    # Accepts a filename as an argument, and checks to see whether that file can be 
    # opened for writing. If it can be opened, it closes the existing Logger object
    # and re-opens it with the new logfile location. It raises an exception if it
    # cannot write to the specified logfile. 
    def Log.set_logfile(new_logfile)
      
      begin
        File.open(new_logfile, 'w') {}
        raise "Couldn't open file #{new_logfile} for writing" unless File.writable?(new_logfile) 
        
        current_log_level = @@log.level
        current_formatter = @@log.formatter
        @@logfile = new_logfile
        @@log = Logger.new(@@logfile)   
        # $stdout.reopen(@@logfile)
        # $stderr.reopen(@@logfile) 
        @@log.level = current_log_level
        @@log.formatter = current_formatter
      rescue Exception => e
        raise e, "Couldn't initialize logfile #{new_logfile}: #{e.backtrace}"
      end
      
    end
    
    # Set the log level. 
    # See http://ruby-doc.org/core/classes/Logger.html for more info. 
    # Possible values are: 
    #   Logger::FATAL (4):  an unhandleable error that results in a program crash
    #   Logger::ERROR (3):  a handleable error condition
    #   Logger::WARN (2): a warning
    #   Logger::INFO (1): generic (useful) information about system operation
    #   Logger::DEBUG (0):  low-level information for developers
    def Log.set_level(loglevel)
     begin
        if [0,1,2,3,4].contains? loglevel
          @@log.level = loglevel
          @@log.debug "Setting LyberCore::Log.level to #{loglevel}"
        else
          @@log.warn "I received an invalid option for log level. I expected a number between 0 and 4 but I got #{loglevel}"
          @@log.warn "I'm setting the loglevel to 0 (debug) because you seem to be having trouble."
          @@log.level = 0
        end
      rescue Exception => e
        raise e, "Couldn't set log level: #{e.backtrace}"
      end
    end
    
    # Return the current log level
    def Log.level
      @@log.level
    end
    
    def Log.fatal(msg)
      @@log.fatal(msg)
    end
    
    def Log.error(msg)
      @@log.error(msg)
    end
    
    def Log.warn(msg)
      @@log.warn(msg)
    end
    
    def Log.info(msg)
      @@log.info(msg)
    end
    
    def Log.debug(msg)
      @@log.debug(msg)
    end
    
    
  end
  
  
end