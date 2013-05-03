require 'net/http'

# Fetch the md5sum of latest.iso
md5sum_uri = URI.parse('https://download.joyent.com/pub/iso/md5sums.txt')
http = Net::HTTP.new(md5sum_uri.host, md5sum_uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
http_body = http.request(Net::HTTP::Get.new(md5sum_uri.request_uri)).body
md5sum = http_body.split("\n").select { |line| line.include?("latest.iso") }[0].split(" ")[0]

password = 'vagrant'

Veewee::Definition.declare({
  :cpu_count => '1',
  :memory_size=> '768',
  :disk_count => '2',
  :disk_size => '15140',
  :disk_format => 'VDI',
  :hostiocache => 'off',
  :hwvirtext => 'on',
  :os_type_id => 'OpenSolaris',
  :iso_file => "smartos-latest.iso",
  :iso_src => "https://download.joyent.com/pub/iso/latest.iso",
  :iso_md5 => md5sum,
  :iso_download_timeout => "1000",
  :skip_iso_transfer => true,
  :boot_wait => "70",
  :boot_cmd_sequence => [
  	'y<Enter><Wait>',
  	'dhcp<Enter><Wait>',
  	'c2t1d0<Enter><Wait>',
  	password + '<Enter><Wait>',
  	password + '<Enter><Wait><Wait>',
  	'y<Enter><Wait>',
  	'n<Enter><Wait>',
  	'y<Enter>'
  ],
# 60 sec
  :ssh_login_timeout => "10000",
  :ssh_user => "root",
  :ssh_password => password,
  :ssh_key => "",
  :ssh_host_port => "7222",
  :ssh_guest_port => "22",
  :sudo_cmd => "%f",
  :shutdown_cmd => "poweroff",
  :postinstall_files => [ "postinstall.sh"],
  :postinstall_timeout => "10000"
})