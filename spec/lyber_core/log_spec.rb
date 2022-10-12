# frozen_string_literal: true

describe LyberCore::Log do
  describe 'initial state' do
    before do
      described_class.restore_defaults
    end

    valid_logfile = '/tmp/fakelog.log'
    invalid_logfile = '/zzxx/fakelog.log'

    before do
      stub_const('ROBOT_ROOT', File.expand_path("#{File.dirname(__FILE__)}/../fixtures"))
    end

    it 'has a default value for logfile' do
      expect(described_class.logfile).to eql(LyberCore::Log::DEFAULT_LOGFILE)
    end

    it 'can set the location of the logfile' do
      described_class.set_logfile(valid_logfile)
      expect(described_class.logfile).to eql(valid_logfile)
    end

    it 'throws an error and does not change location of logfile if passed an invalid location for a logfile' do
      expect { described_class.set_logfile(invalid_logfile) }.to raise_exception(/Couldn't initialize logfile/)
      expect(described_class.logfile).to eql(LyberCore::Log::DEFAULT_LOGFILE)
    end

    it 'can report its log level' do
      expect(described_class).to respond_to(:level)
    end

    it 'starts in info reporting mode (log level 1)' do
      expect(described_class.level).to eql(Logger::INFO)
    end

    it 'can be put into debug mode (log level 0)' do
      described_class.set_level(0)
      expect(described_class.level).to eql(Logger::DEBUG)
    end

    it 'goes into debug mode if it receives an invalid option for loglevel' do
      described_class.set_level('foo')
      expect(described_class.level).to eql(Logger::DEBUG)
    end

    it 'keeps the same logging level when switching to a different file' do
      described_class.set_level(Logger::DEBUG)
      described_class.set_logfile(LyberCore::Log::DEFAULT_LOGFILE)
      described_class.set_logfile(valid_logfile)
      expect(described_class.level).to eql(Logger::DEBUG)
    end

    it 'can write to the log file' do
      onetimefile = '/tmp/onetimefile'
      FileUtils.rm_f onetimefile
      described_class.set_logfile(onetimefile)
      expect(described_class.logfile).to eql(onetimefile)
      described_class.set_level(3)
      expect(File.file?(onetimefile)).to be(true)
      described_class.error('This is an error')
      described_class.debug('Debug info 1')
      described_class.info('This is some info')
      described_class.error('This is another error')
      contents = open(onetimefile, &:read)
      expect(contents).to match(/This is an error/)
      expect(contents).to match(/This is another error/)
      expect(contents).not_to match(/This is some info/)
      expect(contents).not_to match(/Debug info 1/)
      File.delete onetimefile
      expect(File.exist?(onetimefile)).to be(false)
    end

    it 'prints debugging statements when in debugging mode' do
      onetimefile = '/tmp/debugfile'
      FileUtils.rm_f onetimefile
      described_class.set_logfile(onetimefile)
      expect(described_class.logfile).to eql(onetimefile)
      described_class.set_level(0)
      expect(File.file?(onetimefile)).to be(true)
      described_class.debug('Debug info 1')
      described_class.fatal('Oh nooooo!')
      described_class.debug('More debug stuff')
      described_class.info('And here is some info')
      contents = open(onetimefile, &:read)
      expect(contents).to match(/Debug info 1/)
      expect(contents).to match(/Oh nooooo!/)
      File.delete onetimefile
      expect(File.exist?(onetimefile)).to be(false)
    end

    it 'can restore its default state' do
      described_class.restore_defaults
      expect(described_class.level).to eql(LyberCore::Log::DEFAULT_LOG_LEVEL)
      expect(described_class.logfile).to eql(LyberCore::Log::DEFAULT_LOGFILE)
    end

    it 'can format an error message from an exception' do
      re = RuntimeError.new('runtime message')
      re.set_backtrace(caller)
      log_msg = described_class.exception_message(re)
      expect(log_msg).to eql "#{re.inspect}\n#{re.backtrace.join("\n")}"
    end

    it 'will replace newlines with semicolons when logging an exception with a multiline message' do
      msg = "runtime\nmessage"
      re = RuntimeError.new(msg)
      re.set_backtrace(caller)
      log_msg = described_class.exception_message(re)
      expect(log_msg).to eql "#<RuntimeError: runtime; message>\n#{re.backtrace.join("\n")}"
    end

    it 'can log information from any exception object' do
      re = RuntimeError.new('runtime message')
      re.set_backtrace(caller)
      log_msg = described_class.exception_message(re)
      allow(described_class).to receive(:error).with(log_msg)
      described_class.exception(re)
      expect(described_class).to have_received(:error).with(log_msg)
    end
  end
end
