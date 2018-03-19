require 'lyber_core'

describe LyberCore::Log do
  describe 'initial state' do
    before :each do
      LyberCore::Log.restore_defaults
    end

    valid_logfile = '/tmp/fakelog.log'
    invalid_logfile = '/zzxx/fakelog.log'
    with_warnings_suppressed do
      ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + '/../fixtures')
    end

    it 'has a default value for logfile' do
      expect(LyberCore::Log.logfile).to eql(LyberCore::Log::DEFAULT_LOGFILE)
    end

    it 'can set the location of the logfile' do
      LyberCore::Log.set_logfile(valid_logfile)
      expect(LyberCore::Log.logfile).to eql(valid_logfile)
    end

    it 'throws an error and does not change location of logfile if passed an invalid location for a logfile' do
      expect { LyberCore::Log.set_logfile(invalid_logfile) }.to raise_exception(/Couldn't initialize logfile/)
      expect(LyberCore::Log.logfile).to eql(LyberCore::Log::DEFAULT_LOGFILE)
    end

    it 'can report its log level' do
      expect(LyberCore::Log).to respond_to(:level)
    end

    it 'starts in info reporting mode (log level 1)' do
      expect(LyberCore::Log.level).to eql(Logger::INFO)
    end

    it 'can be put into debug mode (log level 0)' do
      LyberCore::Log.set_level(0)
      expect(LyberCore::Log.level).to eql(Logger::DEBUG)
    end

    it 'goes into debug mode if it receives an invalid option for loglevel' do
      LyberCore::Log.set_level('foo')
      expect(LyberCore::Log.level).to eql(Logger::DEBUG)
    end

    it 'keeps the same logging level when switching to a different file' do
      LyberCore::Log.set_level(Logger::DEBUG)
      LyberCore::Log.set_logfile(LyberCore::Log::DEFAULT_LOGFILE)
      LyberCore::Log.set_logfile(valid_logfile)
      expect(LyberCore::Log.level).to eql(Logger::DEBUG)
    end

    it 'can write to the log file' do
      onetimefile = '/tmp/onetimefile'
      File.delete onetimefile if File.exist? onetimefile
      LyberCore::Log.set_logfile(onetimefile)
      expect(LyberCore::Log.logfile).to eql(onetimefile)
      LyberCore::Log.set_level(3)
      expect(File.file?(onetimefile)).to eql(true)
      LyberCore::Log.error('This is an error')
      LyberCore::Log.debug('Debug info 1')
      LyberCore::Log.info('This is some info')
      LyberCore::Log.error('This is another error')
      contents = open(onetimefile, &:read)
      expect(contents).to match(/This is an error/)
      expect(contents).to match(/This is another error/)
      expect(contents).not_to match(/This is some info/)
      expect(contents).not_to match(/Debug info 1/)
      File.delete onetimefile
      expect(File.exist?(onetimefile)).to eql(false)
    end

    it 'prints debugging statements when in debugging mode' do
      onetimefile = '/tmp/debugfile'
      File.delete onetimefile if File.exist? onetimefile
      LyberCore::Log.set_logfile(onetimefile)
      expect(LyberCore::Log.logfile).to eql(onetimefile)
      LyberCore::Log.set_level(0)
      expect(File.file?(onetimefile)).to eql(true)
      LyberCore::Log.debug('Debug info 1')
      LyberCore::Log.fatal('Oh nooooo!')
      LyberCore::Log.debug('More debug stuff')
      LyberCore::Log.info('And here is some info')
      contents = open(onetimefile, &:read)
      expect(contents).to match(/Debug info 1/)
      expect(contents).to match(/Oh nooooo!/)
      File.delete onetimefile
      expect(File.exist?(onetimefile)).to eql(false)
    end

    it 'can restore its default state' do
      LyberCore::Log.restore_defaults
      expect(LyberCore::Log.level).to eql(LyberCore::Log::DEFAULT_LOG_LEVEL)
      expect(LyberCore::Log.logfile).to eql(LyberCore::Log::DEFAULT_LOGFILE)
    end

    it 'can format an error message from an exception' do
      re = RuntimeError.new('runtime message')
      re.set_backtrace(caller)
      log_msg = LyberCore::Log.exception_message(re)
      expect(log_msg).to eql "#{re.inspect}\n" << re.backtrace.join("\n")
    end

    it 'will replace newlines with semicolons when logging an exception with a multiline message' do
      msg = "runtime\nmessage"
      re = RuntimeError.new(msg)
      re.set_backtrace(caller)
      log_msg = LyberCore::Log.exception_message(re)
      expect(log_msg).to eql "#<RuntimeError: runtime; message>\n" << re.backtrace.join("\n")
    end

    it 'can log information from any exception object' do
      re = RuntimeError.new('runtime message')
      re.set_backtrace(caller)
      log_msg = LyberCore::Log.exception_message(re)
      expect(LyberCore::Log).to receive(:error).with(log_msg)
      LyberCore::Log.exception(re)
    end
  end
end
