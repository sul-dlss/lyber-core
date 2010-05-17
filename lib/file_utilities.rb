require 'fileutils'
require 'rubygems'
require 'systemu'

# File Utilities for use in transferring filesystem objects,
# decrypting a file, unpacking a targz archive, and validating checksums
# Author:: rnanders@stanford.edu
class FileUtilities


  # Executes a system command in a subprocess
  #
  # = Inputs:
  # * command = the command to be executed
  #
  # = Return value:
  # * The method will return stdout from the command if execution was successful.
  # * The method will raise an exception if if execution fails
  # The exception's message will contain the explaination of the failure.
  def FileUtilities.execute(command)
    status, stdout, stderr = systemu(command)
    if (status.exitstatus != 0)
      raise stderr
    end
    return stdout
  rescue
    raise "Command failed to execute: #{command}"
  end

  # Generates a dirname for storing or retrieving a file in
  # "pair tree" hierachical structure, where the path is derived
  # from segments of a barcode string
  #
  # = Input:
  # * barcode = barcode string
  #
  # = Return value:
  # * A string containing a slash-delimited dirname derived from the barcode
  def FileUtilities.pair_tree_from_barcode(barcode)
    if (barcode.class != String)
      raise "Barcode must be a String"
    end
    # figure out if this is a SUL barcode or from coordinate library
    library_prefix=barcode[0..4]
    if ( library_prefix == '36105' )
      pair_tree=barcode[5..10].gsub(/(..)/, '\1/')
    else
      library_prefix=barcode[0..2]
      pair_tree=barcode[3..8].gsub(/(..)/, '\1/')
    end
    return "#{library_prefix}/#{pair_tree}"
  end

  # Transfers a filesystem object (file or directory)
  # from a source to a target location. Uses rsync in "archive" mode
  # over an ssh connection.
  #
  # = Inputs:
  # * filename = basename of the filesystem object to be transferred
  # * source_dir = dirname of the source location from which the object is read
  # * dest_dir = dirname of the target location to which the object is written
  # If one of the locations is on a remote server, then the dirname should be
  # prefixed with  user@hosthame:
  #
  # = Return value:
  # * The method will return true if the transfer is successful.
  # * The method will raise an exception if either the rsync command fails,
  # or a test for the existence of the transferred object fails.
  # The exception's message will contain the explaination of the failure
  #
  # Network transfers will only succeed if the appropriate public key
  # authentication has been previously set up.
  def FileUtilities.transfer_object(filename, source_dir, dest_dir)
    source_path=File.join(source_dir, filename)
    rsync='rsync -a -e ssh '
    rsync_cmd = rsync + "'" + source_path + "' " +  dest_dir
    print rsync_cmd + "\n"
    self.execute(rsync_cmd)
    if not File.exists?(File.join(dest_dir, filename))
      raise "#{filename} is not found in  #{dest_dir}"
    end
    return true
  end

  # Decrypts a GPG encrypted file using the "gpg" command
  #
  # = Inputs:
  # * workspace_dir = dirname containing the file
  # * targzgpg = the filename of the GPG encrypted file
  # * targz = the filename of the unencrypted file
  # * passphrase = the string used to decrypt the file
  #
  # = Return value:
  # * The method will return true if the decryption is successful.
  # * The method will raise an exception if either the decryption command fails,
  # or a test for the existence of the decrypted file fails.
  # The exception's message will contain the explaination of the failure
  def FileUtilities.gpgdecrypt(workspace_dir, targzgpg, targz, passphrase)
    print "decrypting #{targzgpg}\n"
    gpg_cmd="/usr/bin/gpg --passphrase '#{passphrase}'  "  +
             "--batch --no-mdc-warning --no-secmem-warning " +
             " --output " + File.join(workspace_dir, targz)  +
            " --decrypt " + File.join(workspace_dir, targzgpg)
    self.execute(gpg_cmd)
    if not File.exists?(File.join(workspace_dir, targz))
      raise "#{targz} was not created in  #{workspace_dir}"
    end
    return true
  end

  # Unpacks a TAR-ed, GZipped archive using a "tar -xzf" command
  #
  # = Inputs:
  # * original_dir = dirname containing the archive file
  # * targz = the filename of the archive file
  # * destination_dir = the target directory into which the contents are written
  #
  # = Return value:
  # * The method will return true if the unpacking is successful.
  # * The method will raise an exception if either the unpack command fails,
  # or a test for the existence of files in the target directory fails.
  # The exception's message will contain the explaination of the failure.
  def FileUtilities.unpack(original_dir, targz, destination_dir)
    print "unpacking #{targz}\n"
    FileUtils.mkdir_p(destination_dir)
    dir_save = Dir.pwd
    Dir.chdir(destination_dir)
    unpack_cmd="tar -xzf " + File.join(original_dir, targz)
    self.execute(unpack_cmd)
    if not (Dir.entries(destination_dir).length > 0)
      raise "#{destination_dir} is empty"
    end
    return true
  ensure
    Dir.chdir(dir_save)
  end

  # Verifies MD5 checksums for the files in a directory
  # against the checksum values in the supplied file
  # (Uses md5sum command)
  #
  # = Inputs:
  # * directory = dirname containing the file to be checked
  # * checksum_file = the name of the file containing the expected checksums
  #
  # = Return value:
  # * The method will return true if the verification is successful.
  # * The method will raise an exception if either the md5sum command fails,
  # or a test of the md5sum output indicates a checksum mismatch.
  # The exception's message will contain the explaination of the failure.
  def FileUtilities.verify_checksums(directory, checksum_file)
    print "verifying checksums in #{directory}\n"
    dir_save = Dir.pwd
    Dir.chdir(directory)
    checksum_cmd = 'md5sum -c ' + checksum_file + ' | grep -v OK | wc -l'
    badcount = self.execute(checksum_cmd).to_i
    if not (badcount==0)
      raise "#{badcount} files had bad checksums"
    end
    return true
  ensure
    Dir.chdir(dir_save)
  end



end