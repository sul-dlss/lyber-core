ENV['RSPEC'] = "true"
module Dor
  CREATE_WORKFLOW = true
  DOR_URI = 'http://dor-dev.stanford.edu/dor'
  WF_URI = 'http://lyberservices-dev.stanford.edu/workflow'
end

DOR_URI = 'http://dor-dev.stanford.edu/dor'
WORKFLOW_URI = 'http://lyberservices-dev.stanford.edu/workflow'

FEDORA_URI = 'https://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora'
SEDORA_USER = 'fedoraAdmin'
SEDORA_PASS = 'fedoraAdmin'
SEDORA_URI= "http://#{SEDORA_USER}:#{SEDORA_PASS}@sdr-fedora-dev.stanford.edu/fedora"
# SEDORA_URI = "http://#{SEDORA_USER}:#{SEDORA_PASS}@localhost:8983/fedora"

#MD_URI = 'http://lyberservices-dev.stanford.edu:8080'
#CONTENT_SERVER_URL = 'http://lyberservices-dev'

CERT_FILE = SSL_CLIENT_CERT_FILE = File.expand_path(File.dirname(__FILE__) + '/../../../certs/ls-dev.crt')
KEY_FILE = SSL_CLIENT_KEY_FILE = File.expand_path(File.dirname(__FILE__) + '/../../../certs/ls-dev.key')
KEY_PASS = SSL_CLIENT_KEY_PASS = 'lsdev'

#SDR_USER_HOST = 'convert@sdr-stage:'
#SDR_DEPOSIT_HOME='/convert/dor/dev'
#SDR_TRIGGER_HOME='/convert/outbound/status-dev'

ENABLE_SOLR_UPDATES = false unless defined? ENABLE_SOLR_UPDATES

DOR_WORKSPACE_DIR="/tmp/dorWorkspaceDir"
SDR_DEPOSIT_DIR=File.expand_path(File.dirname(__FILE__)) << '/../../sdr2_example_objects'
SDR2_EXAMPLE_OBJECTS=File.expand_path(File.dirname(__FILE__)) << '/../../sdr2_example_objects'

SOLR_URL = 'http://127.0.0.1:8983/solr/test'

MSG_BROKER_TIMEOUT = 2

# WORKSPACE_HOME=File.expand_path(File.dirname(__FILE__) + '/../../workspace_home')

Dor::Config.configure do
  robots do
   workspace File.expand_path(File.dirname(__FILE__) + '/../../workspace_home')
  end
end