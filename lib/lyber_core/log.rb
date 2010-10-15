
module LyberCore
  
  class LyberCore::Log
    require 'logger'
        
    # Default values
    default_log_level = 3
        
    @@logfile = "/tmp/lybercore_log.log"
    @@log ||= Logger.new(@@logfile)
    @@log.level = default_log_level
    # @@log = Logger.new()
    
      # @logfile = logfile ? logfile : "/tmp/lybercore_logger.log"
  
    # The current location of the logfile
    def Log.logfile
      return @@logfile
    end
  
    # def Log.log
    #   return @@log
    # end
    
    # Accepts a filename as an argument, and checks to see whether that file can be 
    # opened for writing. If it can be opened, it closes the existing Logger object
    # and re-opens it with the new logfile location. It raises an exception if it
    # cannot write to the specified logfile. 
    def Log.set_logfile(new_logfile)
      
      begin
        File.open(new_logfile, 'w') {}
        raise "Couldn't open file #{new_logfile} for writing" unless File.writable?(new_logfile) 
        @@logfile = new_logfile
        @@log ||= Logger.new(@@logfile)      
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
    
    
  end
  
  
end