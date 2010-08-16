require 'nokogiri'
require 'active_support'

module LyberCore
  module Utils
    class ChecksumValidate
      #Code here

      def self.compare_hashes(hash1, hash2)
           return (hash1 == hash2)
      end

      def self.get_hash_differences(hash1, hash2)
         return hash1.diff(hash2)
      end

      def self.md5_hash_from_md5sum(md5sum)
        checksum_hash = {}
        md5sum.each do |line|
          line.chomp!
          digest,filename = line.split(/[ *]{2}/)
          checksum_hash[filename] = digest.downcase
        end
        return checksum_hash
      end

      def self.md5_hash_from_mets(mets)
        mets_checksum_hash = {}
        doc = Nokogiri::XML(mets)
        doc.xpath('/mets:mets/mets:fileSec//mets:file', {'mets' => 'http://www.loc.gov/METS/'}).each do |filenode|
           digest = filenode.attribute('CHECKSUM')
           if (digest)
             flocat = filenode.xpath('mets:FLocat', {'mets' => 'http://www.loc.gov/METS/'}).first
             if (flocat)
               filename = flocat.attribute_with_ns('href', 'http://www.w3.org/1999/xlink')
               if (filename)
                 mets_checksum_hash[filename.text] = digest.text.downcase
               end
             end
           end
        end
        return mets_checksum_hash
      end

      def self.md5_hash_from_content_metadata(content_md)
        content_md_checksum_hash = {}
        doc = Nokogiri::XML(content_md)
        doc.xpath('/contentMetadata/resource/file').each do |filenode|
           filename = filenode.attribute('id')
           if (filename)
             md5_element = filenode.xpath('checksum[@type="MD5"]').first
             if (md5_element)
               digest = md5_element.text
               if (digest)
                 content_md_checksum_hash[filename.text] = digest.downcase
               end
             end
           end
        end
        return content_md_checksum_hash

      end
    end
  end
end