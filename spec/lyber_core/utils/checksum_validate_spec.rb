require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'ruby-debug'

describe LyberCore::Utils::ChecksumValidate do

  it "should do compare hashes" do
   h1 = { "a" => 1, "c" => 2 }
   h2 = { 7 => 35, "c" => 2, "a" => 1 }
   h3 = { "a" => 1, "c" => 2, 7 => 35 }
   h4 = { "a" => 1, "d" => 2, "f" => 35 }
   h1.should_not == h2   #=> false
   h2.should == h3   #=> true
   h3.should_not == h4   #=> false
   LyberCore::Utils::ChecksumValidate.compare_hashes(h1,h2).should_not == true
   LyberCore::Utils::ChecksumValidate.compare_hashes(h2,h3).should == true
   LyberCore::Utils::ChecksumValidate.compare_hashes(h3,h4).should_not == true
  end

  it "should show hash differences" do
    h1 = { "a" => 1, "c" => 2 }
    h2 = { 7 => 35, "c" => 2, "a" => 1 }
    h3 = { "a" => 1, "c" => 2, 7 => 35 }
    h4 = { "a" => 1, "d" => 2, "f" => 35 }
    diff_h1_h2 = LyberCore::Utils::ChecksumValidate.get_hash_differences(h1,h2)
    diff_h1_h2.should == {7=>35}
  end


  it "should parse md5sum output into a hash" do
md5sum_output = <<MD5END
1234567890  file1
2345678901  file2
3456789012 *file3
MD5END
    md5_hash = LyberCore::Utils::ChecksumValidate.md5_hash_from_md5sum(md5sum_output)
    md5_hash.should == {
            "file1"=>"1234567890",
            "file2"=>"2345678901",
            "file3"=>"3456789012"
    }
  end

  it "should parse mets xml file elements into a hash" do
mets = <<METSXML
<METS:mets xmlns:METS="http://www.loc.gov/METS/"
           xmlns:xlink="http://www.w3.org/1999/xlink" >
  <METS:fileSec>
    <METS:fileGrp ID="FG1" USE="image">
      <!-- normal file entries-->
      <METS:file ID="IMG00000001" MIMETYPE="image/jp2" SEQ="00000001" CREATED="2006-12-04T00:00:00" SIZE="495514" CHECKSUM="f92d161ce013474ad9eb18c741ce3f4d" CHECKSUMTYPE="MD5" OWNERID="9007199256200836-5">
        <METS:FLocat xlink:href="00000001.jp2" LOCTYPE="OTHER" OTHERLOCTYPE="SYSTEM"/>
      </METS:file>
      <METS:file ID="IMG00000002" MIMETYPE="image/jp2" SEQ="00000002" CREATED="2006-12-04T00:00:00" SIZE="173932" CHECKSUM="90155884fec0a79939b8329e59ce0dfc" CHECKSUMTYPE="MD5" OWNERID="9007199256200836-6">
        <METS:FLocat xlink:href="00000002.jp2" LOCTYPE="OTHER" OTHERLOCTYPE="SYSTEM"/>
      </METS:file>
      <METS:file ID="IMG00000003" MIMETYPE="image/jp2" SEQ="00000003" CREATED="2006-12-01T00:00:00" SIZE="4493" CHECKSUM="959351dc0c3dfd21d80f9f05dc9c9461" CHECKSUMTYPE="MD5" OWNERID="9007199256198623-7">
        <METS:FLocat xlink:href="00000003.jp2" LOCTYPE="OTHER" OTHERLOCTYPE="SYSTEM"/>
      </METS:file>
      <!-- missing checksum attribute -->
      <METS:file ID="IMG00000004" MIMETYPE="image/jp2" SEQ="00000004" CREATED="2006-12-01T00:00:00" SIZE="4493"  CHECKSUMTYPE="MD5" OWNERID="9007199256198623-7">
        <METS:FLocat xlink:href="00000004.jp2" LOCTYPE="OTHER" OTHERLOCTYPE="SYSTEM"/>
      </METS:file>
      <!-- missing FLocat child element -->
      <METS:file ID="IMG00000005" MIMETYPE="image/jp2" SEQ="00000005" CREATED="2006-12-01T00:00:00" SIZE="4493" CHECKSUM="959351dc0c3dfd21d80f9f05dc9c9461" CHECKSUMTYPE="MD5" OWNERID="9007199256198623-7">
      </METS:file>
      <!-- missing xlink:href attribute in the FLocat element -->
      <METS:file ID="IMG00000006" MIMETYPE="image/jp2" SEQ="00000006" CREATED="2006-12-01T00:00:00" SIZE="4493" CHECKSUM="959351dc0c3dfd21d80f9f05dc9c9461" CHECKSUMTYPE="MD5" OWNERID="9007199256198623-7">
        <METS:FLocat  LOCTYPE="OTHER" OTHERLOCTYPE="SYSTEM"/>
      </METS:file>
  </METS:fileSec>
</METS>
METSXML
    md5_hash = LyberCore::Utils::ChecksumValidate.md5_hash_from_mets(mets)
    md5_hash.should == {
            "00000001.jp2"=>"f92d161ce013474ad9eb18c741ce3f4d",
            "00000002.jp2"=>"90155884fec0a79939b8329e59ce0dfc",
            "00000003.jp2"=>"959351dc0c3dfd21d80f9f05dc9c9461"
    }
  end

  it "should parse content metadata xml into a checksum hash" do
content_md = <<CONTENTMD
<contentMetadata type="googleScannedBook" objectId="druid:bp119bq5041">
  <resource id="page1" type="page" sequence="1">
    <attr name="googlePageTag">FRONT_COVER IMAGE_ON_PAGE UNTYPICAL_PAGE IMPLICIT_PAGE_NUMBER</attr>
    <file id="00000001.jp2" format="JPEG2000" mimetype="image/jp2" size="495514" preservation="yes">
      <imageData height="2184" width="1432"/>
      <checksum type="MD5">f92d161ce013474ad9eb18c741ce3f4d</checksum>
      <checksum type="SHA-1">499d4fe2622c72660fd7d191b6e64c02712812f6</checksum>
    </file>
    <file id="00000001.html" format="HTML" mimetype="text/html" size="1756" preservation="yes" dataType="hocr">
      <checksum type="MD5">976fbba077ae39e8633865f814f603c2</checksum>
      <checksum type="SHA-1">871280e7f33feb18b5987ba3fcb78b9742edd98d</checksum>
    </file>
  </resource>
  <resource id="page2" type="page" sequence="2">
    <attr name="googlePageTag">IMAGE_ON_PAGE UNTYPICAL_PAGE IMPLICIT_PAGE_NUMBER</attr>
    <file id="00000002.jp2" format="JPEG2000" mimetype="image/jp2" size="173932" preservation="yes">
      <imageData height="2120" width="1424"/>
      <checksum type="MD5">90155884fec0a79939b8329e59ce0dfc</checksum>
      <checksum type="SHA-1">c0ec5d472400b2d129ff5ef2ce52ad6d46996b72</checksum>
    </file>
    <file id="00000002.html" format="HTML" mimetype="text/html" size="3747" preservation="yes" dataType="hocr">
      <checksum type="MD5">7152737fb944cc16409380af582a271e</checksum>
      <checksum type="SHA-1">f0a8821412c50cff4e68331b3446fcfb7f6bb817</checksum>
    </file>
  </resource>
</contentMetadata>
CONTENTMD
    md5_hash = LyberCore::Utils::ChecksumValidate.md5_hash_from_content_metadata(content_md)
    md5_hash.should == {
            "00000001.jp2"=>"f92d161ce013474ad9eb18c741ce3f4d" ,
            "00000001.html"=>"976fbba077ae39e8633865f814f603c2",
            "00000002.jp2"=>"90155884fec0a79939b8329e59ce0dfc",
            "00000002.html"=>"7152737fb944cc16409380af582a271e" 
    }

  end

end