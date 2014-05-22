require 'pathname'

# Returns an array of Hash objects
# Each object contains the following keys:
# :dev_file, :uuid, :label, :type
def getUSBDrives
  entries = Dir.entries('/dev/disk/by-id').map do |d|
    Pathname.new(File.join('/dev/disk/by-id',d)).realpath if d[/^(?:usb)|(?:mmc)-\S+$/]
  end.compact.uniq
  return [] if entries.empty?
  if !`which blkid`.empty?
    retval = `blkid #{entries.join(' ')}`.each_line.map do |d|
      d.strip.match(/^(?<dev_file>\S+):(?:(?:\s*UUID="(?<uuid>[^"]+)")|(?:\s*LABEL="(?<label>[^"]+)")|(?:\s*TYPE="(?<type>[^"]+)"))*\s*$/)
    end
    return retval.map do |match|
      Hash[ match.names.map { |n| n.to_sym }.zip(match.captures) ]
    end
  elsif !`which vol_id`.empty?
    # TODO test on a machine that has vol_id
    retval = []
    entries.each do |dev|
      entry = {}
      entry[:dev_file] = dev
      entry[:uuid] = `vol_id -u #{dev}`
      entry[:label] = `vol_id -l #{dev}`
      entry[:type] = `vol_id -t #{dev}`
      retval << entry
    end
    return retval
  else
    raise 'Cannot find blkid or vol_id'
  end
end
