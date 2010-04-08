require 'fileutils'

class FileUtilities

  def FileUtilities.pair_tree_from_barcode(barcode)
    # figure out if this is a SUL barcode or from coordinate library
    library_prefix=barcode[0..4]
    if ( library_prefix == '36105' )
      pair_tree=barcode[5..10].gsub(/(..)/, '\1/')
    else
      library_prefix=barcode[0..2]
      pair_tree=barcode[3..8].gsub(/(..)/, '\1/')
    end
    return "#{library_prefix}/#{pair_tree}/"
  end

  def FileUtilities.transfer_object(filename, source_dir, workspace_dir)
    source_path=File.join(source_dir, filename)
    rsync='rsync -a -e ssh '
    rsync_cmd = rsync + "'" + source_path + "' " +  workspace_dir
    print rsync_cmd + "\n"
    system(rsync_cmd)
    return File.exists?(File.join(workspace_dir, filename))
  end

  def FileUtilities.decrypt(workspace_dir, targzgpg, targz)
    print "decrypting #{targzgpg}\n"
    gpg_cmd="/usr/bin/gpg --passphrase 'awn mudd golf ella fawn cry wino turn eve fine odin dub' "  +
             "--batch --no-mdc-warning --no-secmem-warning " +
             " --output " + File.join(workspace_dir, targz)  +
            " --decrypt " + File.join(workspace_dir, targzgpg)
    system(gpg_cmd)
    return File.exists?(File.join(workspace_dir, targz))
  end

  def FileUtilities.unpack(original_dir, targz, destination_dir)
    print "unpacking #{targz}\n"
    FileUtils.mkdir_p(destination_dir)
    dir_save = Dir.pwd
    Dir.chdir(destination_dir)
    unpack_cmd="tar -xzf " + File.join(original_dir, targz)
    system(unpack_cmd)
    Dir.chdir(dir_save)
    return (Dir.entries(destination_dir).length > 0)
  end

  def FileUtilities.verify_checksums(directory, checksum_file)
    print "verifying checksums in #{directory}\n"
    dir_save = Dir.pwd
    Dir.chdir(directory)
    checksum_cmd = 'md5sum -c ' + checksum_file + ' | grep -v OK | wc -l'
    badcount = `#{checksum_cmd}`.to_i
    Dir.chdir(dir_save)
    return (badcount==0)
  end



end