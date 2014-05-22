# Author - Aaron Atamian
# RepairTech Inc.

require 'green_shoes'
require 'open-uri'
require 'tempfile'
require 'digest/md5'
load 'functions.rb'

def writefile(name, text)
  File.open(name, 'w') do |file|
    file.puts text
  end
end

Shoes.app(title: "TechUSB Creator", width: 349, height: 550, resizable: false) do

  image "TechUSB.png", width: 320, height: 84, margin_left: 15
  para "Creator", :size => 24, :align => "center"
  stack(margin: 10) do
    # determines if program is being run as root
    if Process.uid !=0 then
      para "This application must be run as root."
    else
      drives = getUSBDrives
      # authentication info
      para "Account Email"
      email = edit_line
      para "Authentication Key"
      key = edit_line
      para "Choose a drive"

      drive = nil
      filename = nil

      flow do
        @list = list_box items: drives.collect { |d| d[:dev_file]}, width: 100
        @list.choose @list.items.first unless @list.items.empty?
        drive = @list.text
        @refresh_button = button("Refresh", margin_left: 20) do
          drives = getUSBDrives
          @list.items = drives.collect { |d| d[:dev_file]}
        end
      end
      #checkparam is used because the scope of @checkbox does not exist outside of this app window
      checkparam = nil;
      isoFiles = Array.new

      flow do
        # adding Custom ISOs
        @addisos_button = button("Add", margin_left: 20)
        @isoStack = stack do
          # nothing yet
        end
        @addisos_button.click do
          isoFiles.push(ask_open_file)
          @isoStack.append do
            flow do
              @rmiso = check(width: 10)
              para isoFiles.last, {width: 300}
            end
          end
        end
        @removeiso = button("Remove selected", margin_left: 20) do
          @isoStack.contents.each do |f|
            c = f.contents[0]
            if c.checked?
              isoFiles.delete_at(isoFiles.find_index(f.contents[1].text))
            end
          end
          # clears isoStack and readds the corresponding elements back
          @isoStack.clear do
            isoFiles.each do |iso|
              flow do
                check(width: 10)
                para iso, {width: 300}
              end
            end
          end
        end
      end
      flow do
        # asks user if usb drive will be formatted
        @checkbox = check(width: 10, checked: true)
        if @checkbox.checked?
          checkparam = true
        else
          checkparam = false
        end
        para "Format drive before installing?", {width: 300}
        @download_button = button("Download & Install") do

          installing = window(title: "TechUSB Creator", width: 349, height: 100, resizable: false) do

            @text = para "TechUSB download in progress...", margin_left: 40
            @download = para "Unetbootin is downloading...", margin_left: 40

            # open-uri event handlers (progress bars)
            @unet_progress_bar = progress(top:50, left: 100)
            @unet_content_length_proc = lambda do |content_length|
              @unet_content_length = content_length
            end
            @unet_progress_proc = lambda do |bytes|
              @unet_progress_bar.fraction = bytes / @unet_content_length.round(1)
            end

            @techusb_progress_bar = progress(top:70, left: 100)
            @techusb_content_length_proc = lambda do |content_length|
              @techusb_content_length = content_length
            end
            @techusb_progress_proc = lambda do |bytes|
              @techusb_progress_bar.fraction = bytes / @techusb_content_length.round(1)
            end

            # threads created to download the required files
            Thread.new do

              unet = Thread.new do

                unetOptions = {
                  :content_length_proc => @unet_content_length_proc,
                  :progress_proc => @unet_progress_proc
                }

                # compares current file (if there is one) to MD5 checksum
                unetOptions['If-None-Match'] = Digest::MD5.hexdigest(File.read("unetbootin")) if File.exists?("unetbootin")

                begin
                  open("https://8a460776177d49c765ce-a2065d3226b6f083a3fe1d53a8aa037e.ssl.cf1.rackcdn.com/unetbootin-linux-585", "rb", unetOptions) do |dl|
                    if (dl.status[0] == "200")
                      open("unetbootin", "wb") do |f|
                        f.write dl.read
                      end
                    end
                  end
                rescue OpenURI::HTTPError => e
                  puts "Not downloading unetbootin : #{e}"
                end

                @download.text = "Techusb.iso is downloading..."
                @unet_progress_bar.remove
                `chmod +x unetbootin`
              end

              techusb = Thread.new do
                techusbOptions = {
                  :content_length_proc => @techusb_content_length_proc,
                  :progress_proc => @techusb_progress_proc
                }

                # compares current file (if there is one) with MD5 checksum
                techusbOptions['If-None-Match'] = Digest::MD5.hexdigest(File.read("techusb.iso")) if File.exists?("techusb.iso")
                begin
                  open("https://8a460776177d49c765ce-a2065d3226b6f083a3fe1d53a8aa037e.ssl.cf1.rackcdn.com/techusb.iso", "rb", techusbOptions) do |dl|

                    if (dl.status[0] == "200")
                      open("techusb.iso", "wb") do |f|
                        f.write dl.read
                      end
                    end
                  end
                rescue OpenURI::HTTPError => e
                  puts "Not downloading techusb.iso : #{e}"
                end

                @techusb_progress_bar.remove
                @download.remove
                @text.text = "Installation in progress..."
              end

              unet.join
              techusb.join
              puts 'joined'
              fileName = "techusb.iso"
              mount = nil
              mtab = File.read("/etc/mtab")
              mtab.split(/\n/).each do |line|
                d, m = line.split(" ")
                mount = m if d == drive
              end

              if mount.nil?
                mount = "/mnt/techusb"
                `mkdir -p #{mount}`
              end

              # determines if user wants the USB drive formatted
              if checkparam == true
                `umount #{drive}` rescue puts 'error on umount'
                `mkfs.vfat -n TECHUSB #{drive}` rescue puts 'error on mkfs'
                `mkdir -p #{mount}`
                `mount #{drive} #{mount}`
              end

              # runs UnetBootin
              `./unetbootin method=diskimage isofile=#{fileName} targetdrive=#{drive} autoinstall=yes`

              unless mount.nil?
                `mv #{mount}/syslinux.cfg #{mount}/syslinux.old`
                `rm -rf #{mount}/boot/syslinux`
                `mv  #{mount}/boot/isolinux #{mount}/boot/syslinux`
                `mv #{mount}/boot/syslinux/isolinux.cfg #{mount}/boot/syslinux/syslinux.cfg`
                `mv #{mount}/boot/syslinux/isolinux.bin #{mount}/boot/syslinux/syslinux.bin`
              end

              writefile("#{mount}/email.txt", email.text)
              writefile("#{mount}/key.txt", key.text)

              # adds ISOs to TechUSB and updates knoppix.menu
              unless isoFiles.empty?
                FileUtils.mkdir_p("#{mount}/Boot/ISOs/")
                File.open("#{mount}/Boot/Syslinux/knoppix.menu", "a") do |file|
                  file.puts ""
                  file.puts "MENU BEGIN customisos"
                  file.puts "  MENU TITLE Custom ISOs"
                  file.puts "  MENU SEPERATOR"
                  isoFiles.each_with_index do |iso, index|
                    file.puts ""
                    file.puts "  LABEL iso#{index}"
                    file.puts "    MENU LABEL #{File.basename(iso)}"
                    file.puts "    KERNEL grub.exe"
                    file.puts "    APPEND --config-file=\"map /boot/ISOs/#{File.basename(iso)} (0xff);map --hook;chainloader (0xff)\""
                    file.puts ""
                    FileUtils.cp(iso, "#{mount}/Boot/ISOs")
                  end
                end
              end
              @text.text = "Done!"
              button("OK", top: 35, left: 100) do
                installing.close()
              end
            end
          end
        end
      end
    end
  end
end
