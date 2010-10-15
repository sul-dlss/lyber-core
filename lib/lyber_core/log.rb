
module LyberCore
  
  class LyberCore::Log
    require 'logger'
        
    @@logfile = "/tmp/lybercore_log.log"
    @@log ||= Logger.new(@@logfile, 20, 'daily')
    # @@log = Logger.new()
    
      # @logfile = logfile ? logfile : "/tmp/lybercore_logger.log"
  
    # The current location of the logfile
    def Log.logfile
      return @@logfile
    end
  
    # def Log.log
    #   return @@log
    # end
    
    def Log.set_logfile(new_logfile)
      
      begin
        File.open(new_logfile, 'w') {}
        raise "Couldn't open file #{filename} for writing" unless File.writable?(new_logfile) 
        @@log.close
        @@logfile = new_logfile
        @@log ||= Logger.new(@@logfile, 20, 'daily')      
      rescue Exception => e
        raise e, "Couldn't initialize logfile: #{e.backtrace}"
      end
      
    end
    
    
  end
  
  
end