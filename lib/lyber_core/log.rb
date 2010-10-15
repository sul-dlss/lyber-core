
module LyberCore
  
  class LyberCore::Log
    require 'logger'
        
    @@logfile = "/tmp/lybercore_log.log"
    @@log ||= Logger.new(@@logfile, 20, 'daily')
    # @@log = Logger.new()
    
      # @logfile = logfile ? logfile : "/tmp/lybercore_logger.log"
  
    def Log.logfile
      return @@logfile
    end
  
    def Log.log
      # return @@log.logfile
      return @@log
    end
    
    
    
  end
  
  
end