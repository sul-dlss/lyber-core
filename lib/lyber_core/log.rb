
module LyberCore
  
  class LyberCore::Log
    require 'logger'
        
    # Default values
    DEFAULT_LOGFILE = "/tmp/lybercore_log.log"
    DEFAULT_LOG_LEVEL = Logger::INFO
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
        current_log_level = @@log.level
        current_formatter = @@log.formatter
        @@log = Logger.new(new_logfile)
        @@logfile = new_logfile
        @@log.level = current_log_level
        @@log.formatter = current_formatter
      rescue Exception => e
        raise e, "Couldn't initialize logfile #{new_logfile} because\n#{e.message}: #{e.backtrace.join(%{\n})}}"
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
        if [0,1,2,3,4].include? loglevel
          @@log.level = loglevel
          @@log.debug "Setting LyberCore::Log.level to #{loglevel}"
        else
          @@log.warn "I received an invalid option for log level. I expected a number between 0 and 4 but I got #{loglevel}"
          @@log.warn "I'm setting the loglevel to 0 (debug) because you seem to be having trouble."
          @@log.level = 0
        end
      rescue Exception => e
        raise e, "Couldn't set log level because\n#{e.message}: #{e.backtrace.join(%{\n})}"
      end
    end
    
    # Return the current log level
    def Log.level
      @@log.level
    end
    
    def Log.fatal(msg)
      @@log.add(Logger::FATAL) { msg }
    end
    
    def Log.error(msg)
      @@log.add(Logger::ERROR) { msg }
    end
    
    def Log.warn(msg)
      @@log.add(Logger::WARN) { msg }
    end
    
    def Log.info(msg)
      @@log.add(Logger::INFO) { msg }
    end
    
    def Log.debug(msg)
      @@log.add(Logger::DEBUG) { msg }
    end

    def Log.exception(e)
      msg = Log.exception_message(e)
      if e.is_a?(LyberCore::Exceptions::FatalError)
        Log.fatal(msg)
      else
        Log.error(msg)
      end
    end

    def Log.exception_message(e)
      msg = e.inspect.split($/).join('; ') + " " + e.backtrace.inspect
    end
    
  end
  
  
end