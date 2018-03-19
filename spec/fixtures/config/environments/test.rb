ENV['RSPEC'] = 'true'

Dor::Config.configure do
  fedora do
    url 'https://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora'
    cert_file File.expand_path(File.dirname(__FILE__) + '/../../../certs/ls-dev.crt')
    key_file File.expand_path(File.dirname(__FILE__) + '/../../../certs/ls-dev.key')
    key_pass 'lsdev'
  end

  solrizer.url 'http://127.0.0.1:8983/solr/test'

  robots do
    workspace File.expand_path(File.dirname(__FILE__) + '/../../workspace_home')
  end

  sedora do
    'http://fedoraAdmin:fedoraAdmin@sdr-fedora-dev.stanford.edu/fedora'
    cert_file File.expand_path(File.dirname(__FILE__) + '/../../../certs/ls-dev.crt')
    key_file File.expand_path(File.dirname(__FILE__) + '/../../../certs/ls-dev.key')
    key_pass 'lsdev'

    deposit_dir __dir__ << '/../../sdr2_example_objects'
    example_objects __dir__ << '/../../sdr2_example_objects'
  end

  workflow.url 'http://lyberservices-dev.stanford.edu/workflow'
end

MSG_BROKER_TIMEOUT = 2
