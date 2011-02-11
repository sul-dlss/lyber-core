require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'xml_models/identity_metadata/identity_metadata'

class TestIdentityMetadata < Test::Unit::TestCase

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
    idmd_xml = IdentityMetadata.from_xml(File.read(File.join(File.dirname(__FILE__), "../test_data/IdentityMetadata-before.xml")))
    assert_equal("druid:rt923jk342",idmd_xml.objectId)
    assert_equal("STANFORD_342837261527",idmd_xml.sourceId.value)
    assert_equal("google",idmd_xml.sourceId.source)
    assert_equal("342837261527",idmd_xml.otherIds[0].value)
    assert_equal("catkey",idmd_xml.otherIds[1].name)
    assert_equal("Google Books : Phase 1",idmd_xml.tags[0].value)
  end

  def test_modify
    idmd_xml = IdentityMetadata.from_xml(File.read(File.join(File.dirname(__FILE__) ,'../test_data/IdentityMetadata-before.xml')))
    citationTitle = idmd_xml.citationTitle
    assert_equal("",citationTitle)
    idmd_xml.citationTitle='Squirrels of North America'
    idmd_xml.citationCreator='Eder, Tamara, 1974-'
    assert_equal(2,idmd_xml.tags.size)
    idmd_xml.add_tag('Google Books : US pre-1923')
    # Second attempt to add same tag will be ignored
    idmd_xml.add_tag('Google Books : US pre-1923')
    idmd_xml = idmd_xml.to_xml
    idmd_str = idmd_xml.to_s
    expected_roxml = IdentityMetadata.from_xml(File.read(File.join(File.dirname(__FILE__) ,'../test_data/IdentityMetadata-after.xml')))
    expected_xml = expected_roxml.to_xml
    expected_str = expected_xml.to_s
    assert_equal(expected_str,idmd_str)
  end

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

end