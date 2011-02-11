require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'xml_models/identity_metadata/dublin_core'

class TestDublinCore < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end



  def test_parse
    dcmd_xml = DublinCore.from_xml(File.read(File.join(File.dirname(__FILE__), "../test_data/dc-test.xml")))
    assert_equal("The adventures of Gil Blas of Santillane" ,dcmd_xml.title[0])
    assert_equal("Le Sage, Alain Rene" ,dcmd_xml.creator[0])
    assert_equal("Smollett, Tobias George" ,dcmd_xml.creator[1])
    assert_equal("xmlSubject2" ,dcmd_xml.subject[1])
    assert_equal("xmlDescription" ,dcmd_xml.description[0])
    assert_equal("xmlPublisher" ,dcmd_xml.publisher[0])
    assert_equal("xmlContributor" ,dcmd_xml.contributor[0])
    assert_equal("xmlDate", dcmd_xml.date[0])
    assert_equal("xmlType", dcmd_xml.type[0])
    assert_equal("xmlFormat", dcmd_xml.format[0])
    assert_equal("xmlIdentifier",dcmd_xml.identifier[0])
    assert_equal( "xmlSource",dcmd_xml.source[0])
    assert_equal( "xmlLanguage",dcmd_xml.language[0])
    assert_equal("xmlRelation",dcmd_xml.relation[0])
    assert_equal("xmlCoverage",dcmd_xml.coverage[0])
    assert_equal("xmlRights",dcmd_xml.rights[0])
  end

  def test_modify
    dcmd_xml = DublinCore.from_xml(File.read(File.join(File.dirname(__FILE__) ,'../test_data/dc-test.xml')))
    
    dcmd_xml.title = "Changed The Title"
    dcmd_xml.creator = ["Foo", "Bar", "Yoo"]
    
    assert_equal(3, dcmd_xml.creator.length)
    
    expected_dc = DublinCore.from_xml(File.read(File.join(File.dirname(__FILE__) ,'../test_data/dc-test-after.xml')))
    expected_xml = expected_dc.to_xml
    assert_equal(expected_xml, dcmd_xml.to_xml)
    
  end
=begin
  def test_identifiers
    idmd_xml = IdentityMetadata.from_xml(File.read(File.join(File.dirname(__FILE__) ,'../test_data/IdentityMetadata-before.xml')))
    barcode = idmd_xml.get_identifier_value('barcode')
    assert_equal('342837261527', barcode )
    uuid  = idmd_xml.get_identifier_value('uuid')
    assert_equal('7f3da130-7b02-11de-8a39-0800200c9a66', uuid )
    pairs = idmd_xml.get_id_pairs
    assert_equal('catkey:129483625', pairs[1] )
  end

  def test_add_identifiers
    idmd_xml = IdentityMetadata.new
    idmd_xml.add_identifier('barcode', 'mybarcode')
    idmd_xml.add_identifier('catkey', 'mycatkey')
    assert_equal(2,idmd_xml.otherIds.size)
    barcode = idmd_xml.get_identifier_value('barcode')
    assert_equal('mybarcode', barcode )
  end
=end

end