require 'rubygems'
require 'roxml'

#<oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
#xmlns:srw_dc="info:srw/schema/1/dc-schema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
#xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://cosimo.stanford.edu/standards/oai_dc/v2/oai_dc.xsd">
#  <dc:title>Life of Abraham Lincoln, sixteenth president of the United States: Containing his early
#history and political career; together with the speeches, messages, proclamations and other official
#documents illus. of his eventful administration</dc:title>
#  <dc:creator>Crosby, Frank.</dc:creator>
#  <dc:format>text</dc:format>
#  <dc:language>eng</dc:language>
#  <dc:subject>E457 .C94</dc:subject>
#  <dc:identifier>lccn:11030686</dc:identifier>
#  <dc:identifier>callseq:1</dc:identifier>
#  <dc:identifier>shelfseq:973.7111 .L731CR</dc:identifier>
#  <dc:identifier>catkey:1206382</dc:identifier>
#  <dc:identifier>barcode:36105005459602</dc:identifier>
#  <dc:identifier>uuid:ddcf5f1a-0331-4345-beca-e66f7db276eb</dc:identifier>
#  <dc:identifier>google:STANFORD_36105005459602</dc:identifier>
#  <dc:identifier>druid:ng786kn0371</dc:identifier>
#</oai_dc:dc>

class DublinCore
  include ROXML
  xml_namespaces \
    :oai_dc => "http://www.openarchives.org/OAI/2.0/oai_dc/",
        :dc => "http://purl.org/dc/elements/1.1/"

  xml_name :root => 'oai_dc:dc'
  xml_reader :title, :as => [], :from => 'dc:title'
  xml_reader :creator, :as => [], :from => 'dc:creator'
  xml_reader :subject, :as => [], :from => 'dc:subject'
  xml_reader :description, :as => [], :from => 'dc:description'
  xml_reader :publisher, :as => [], :from => 'dc:publisher'
  xml_reader :contributor, :as => [], :from => 'dc:contributor'
  xml_reader :date, :as => [], :from => 'dc:date'
  xml_reader :type, :as => [], :from => 'dc:type'
  xml_reader :format, :as => [], :from => 'dc:format'
  xml_reader :identifier, :as => [], :from => 'dc:identifier'
  xml_reader :source, :as => [], :from => 'dc:source'
  xml_reader :language, :as => [], :from => 'dc:language'
  xml_reader :relation, :as => [], :from => 'dc:relation'
  xml_reader :coverage, :as => [], :from => 'dc:coverage'
  xml_reader :rights, :as => [], :from => 'dc:rights'
end
