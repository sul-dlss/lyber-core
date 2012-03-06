require 'find'
require 'fileutils'
require 'bagit'     # http://github.com/flazz/bagit

module LyberCore
  module Utils
    class BagitBag

      def initialize(bag_dir)
        @bag_dir = bag_dir
        if (File.exist?(@bag_dir))
          FileUtils.rm_r(@bag_dir)
        end
        @bag = BagIt::Bag.new @bag_dir
      end

      def add_content_files(source_dir, use_links)
        data_content_dir = File.join(@bag_dir, 'data', 'content')
        copy_dir(source_dir,data_content_dir, use_links)
      end

      def copy_dir(source_dir, target_dir, use_links)
        FileUtils.mkdir_p(target_dir)
        Dir.foreach(source_dir)  do  |file|
          unless (file == '.' or file == '..')
            source_file = File.join(source_dir, file)
            target_file = File.join(target_dir, file)
            if File.directory?(source_file)
              copy_dir(source_file, target_file, use_links)
            elsif (use_links)
              File.link(source_file, target_file)
            else
              File.copy(source_file, target_file)
            end
          end
        end
      end

      def add_metadata_file_from_string( metadata_string, file_name)
        if (not metadata_string.nil? )
          data_file_path = "metadata/#{file_name}"
          @bag.add_file(data_file_path) do |io|
            io.puts metadata_string
          end
        end
      end

      def write_metadata_info(md_hash)
        payload = bag_payload()
        bag_info_hash = {
          'Bag-Size' =>  bag_size_human(payload[0]),
          'Payload-Oxum' =>  "#{payload[0]}.#{payload[1]}",
        }
        @bag.write_bag_info(md_hash.merge(bag_info_hash))
        File.rename(@bag.bag_info_txt_file, File.join(@bag.bag_dir,'bag-info.txt'))
      end

      def bag_payload()
        bytes = 0
        files = 0
        Find.find(@bag.data_dir) do |filepath|
          if (not File.directory?(filepath))
            bytes += File.size(filepath)
            files += 1
          end
        end
        return [bytes, files]
      end

      def bag_size_human(bytes)
        count = 0
        size = bytes
        while ( size >= 1000 and count < 4 )
          size /= 1000.0
          count += 1
        end
        if (count == 0)
          return sprintf("%d B", size)
        else
          return sprintf("%.2f %s", size, %w[B KB MB GB TB][count] )
        end
      end

      def write_manifests()
        @bag.manifest!
        @bag.tagmanifest!
      end

      def validate()
        if not @bag.valid?
         raise "bag not valid: #{@bag_dir}"
       end

      end

    end

  end
end