require 'rubygems'
require 'roxml'

#<identityMetadata>
#     <objectId>druid:rt923jk342</objectId>
#     <objectType>item</objectType>
#     <objectLabel>google download barcode 36105049267078</objectLabel>
#     <objectCreator>DOR</objectCreator>
#     <citationTitle>Squirrels of North America</citationTitle>
#     <citationCreator>Eder, Tamara, 1974-</citationCreator>
#     <sourceId source="google">STANFORD_342837261527</sourceId>
#     <otherId name="barcode">342837261527</otherId>
#     <otherId name="catkey">129483625</otherId>
#     <otherId name="uuid">7f3da130-7b02-11de-8a39-0800200c9a66</otherId>
#     <agreementId>druid:yh72ms9133</agreementId>
#     <tag>Google Books : Phase 1</tag>
#     <tag>Google Books : Scan source STANFORD</tag>
#</identityMetadata>

class SourceId
  include ROXML

  xml_name :sourceId
  xml_accessor :source, :from => '@source'
  xml_accessor :value, :from => :content
end

class OtherId
  include ROXML

  xml_name :otherId
  xml_accessor :name, :from => '@name'
  xml_accessor :value, :from => :content
end

class Tag
  include ROXML
  xml_name :tag
  xml_accessor :value, :from => :content
end

class IdentityMetadata
  include ROXML

  xml_name :identityMetadata
  xml_reader :objectId
  xml_reader :objectType
  xml_reader :objectLabel
  xml_reader :objectCreator
  xml_accessor :citationTitle
  xml_accessor :citationCreator
  xml_accessor :sourceId, :as => SourceId
  xml_accessor :otherIds, :as => [OtherId]
  xml_reader :agreementId
  xml_accessor :tags, :as => [Tag]

  # Add a new tag to the IdentityMetadata instance
  def add_tag(new_tag_value)
    # Make sure tag is not already present
    for tag in @tags do
      if (tag.value == new_tag_value )
        return
      end
    end
    tag = Tag.new
    tag.value = new_tag_value
    @tags << tag
  end

  # Return the OtherId object for the specified identier name
  def get_other_id(key)
    if (@otherIds != nil)
      for other_id in @otherIds do
        return other_id  if (other_id.name == key)
      end      
    end
    return nil
  end

  # Return the identifier value for the specified identier name
  def get_identifier_value(key)
    other_id = self.get_other_id(key)
    if (other_id != nil)
      return other_id.value
    end
    raise "No #{key} indentifier found for druid #{@objectId}"
  end

  # Add a new name,value pair to the set of identifiers
  def add_identifier(key, value)
    other_id = self.get_other_id(key)
    if (other_id != nil)
      other_id.value = value
    else
      other_id = OtherId.new
      other_id.name = key
      other_id.value = value
      if (@otherIds == nil)
         @otherIds = [other_id]
      else
        @otherIds <<  other_id
      end
    end
  end

  # Return an array of strings where each entry consists of name:value
  def get_id_pairs
    pairs=Array.new
    if (@otherIds != nil)
      @otherIds.each do |other_id|
        pairs << "#{other_id.name}:#{other_id.value}"
      end
    end
    return pairs
  end

end