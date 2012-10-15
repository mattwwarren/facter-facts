# This fact was created to find all unique IP networks on a server.
# Currently, there is NO compatibility with IPv6, sorry
# Original code snippets taken from ipaddresses fact found somewhere on the Internet.
# Author: Matt Warren <matt@warrencomputing.net>
# Last Modified: 11 Oct 2012

require 'facter/util/ip'
require 'rubygems'
# Try to load the dependent gem and complain if it doesn't go.
begin 
  require 'netaddr'
rescue
  raise unless e.message =~ /netaddr/
  puts "Cannot get unique networks without dependent netaddr gem" 
end
 
# We only care about an interface if it has an address
# This handy function will tell if that's true

def has_address(interface)
  ip = Facter::Util::IP.get_interface_value(interface, 'ipaddress')
  if ip.nil?
    false
  else
    true
  end
end

Facter.add(:uniquenetworks) do
  setcode do 
    # Initializing variables, apologies for the terrible names
    ip = ""
    netmask = ""
    tocheck = ""
    newcidr = ""
    fixedcidr = ""
    tochecks = Hash.new
    checkedcidrs = Array.new
    # Start the fun
    Facter::Util::IP.get_interfaces.each do |interface|
      if has_address(interface)
        ip = Facter::Util::IP.get_interface_value(interface, 'ipaddress')
        netmask = Facter::Util::IP.get_interface_value(interface, 'netmask')
      end
      # Create a hash of ipaddresses and netmasks for checking
      tochecks[ip] = netmask
    end
    # Iterate through the hash and find unique networks
    tochecks.each_pair do |key, value|
      newcidr = ""
      fixedcidr = ""
      if key.length > 0
        if checkedcidrs.empty?
          checkedcidrs.push(NetAddr::CIDR.create("#{key}/#{value}").to_s)
        else
          checkedcidrs.each do |cidr|
            # Had some weirdness here with cidr being a string if I didn't do create
            # But create saw it as a NetAddr::CIDR.
            # It was late so I threw in this voodoo.
            if NetAddr::CIDR.create(cidr.to_s).contains?(tocheck)
            else
              newcidr = NetAddr::CIDR.create("#{tocheck}/#{value}")
            end
          end
        end
      end
      if newcidr.to_s.length > 0
        # uniq doesn't work if it's not a string, so convert it.
        checkedcidrs.push(newcidr.to_s)
      end
    end
    puts checkedcidrs.uniq.join(",")
  end
end
