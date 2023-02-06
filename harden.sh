#!/bin/bash

#run this in a public setting

if [ "$EUID" -ne 0 ]
  then echo "Not ROOT"
    echo "quiting..."
  exit
fi

echo "printing status"
systemctl status > serviceOut.txt
cat /etc/systemd/network/20-wlan.network | grep -i dns >> serviceOut.txt
cat /etc/systemd/resolved.conf.d/dns_servers.conf | grep -i dns >> serviceOut.txt
cat /etc/NetworkManager/conf.d/dns.conf >> serviceOut.txt

echo "Changing DNS..."

read -p "Use Cloudflare && Google? [Y/n] " ans && [[ $ans == [yY] || $ans == [yY][eE][sS] ]] || exit

#changing dropins
cat > /etc/systemd/resolved.conf.d/dns_servers.conf <<-EOF 
    [Resolve]
    # Some examples of DNS servers which may be used for DNS= and FallbackDNS=:
    # Cloudflare: 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
    # Google:     8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google
    # Quad9:      9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
    DNS=1.1.1.1 2606:4700:4700::1111
    FallbackDNS=8.8.8.8
    Domains=~.
    DNSSEC=true
    DNSOverTLS=opportunistic
    MulticastDNS=no
    LLMNR=no
    #Cache=yes
    #CacheFromLocalhost=no
    DNSStubListener=yes
    #DNSStubListenerExtra=
    #ReadEtcHosts=yes
    #ResolveUnicastSingleLabel=no
EOF 

cat > /etc/NetworkManager/conf.d/dns.conf <<-EOF
    [main]
    dns = systemd-resolved
EOF


 
#avahi and cups -----
systemctl disable avahi-daemon.service
systemctl stop avahi-daemon.service
systemctl disable avahi-daemon.socket
systemctl stop avahi-daemon.socket
systemctl disable cups
systemctl stop cups

#restart / shutdown networking
systemctl daemon-reload
systemctl restart systemd-resolved
systemctl restart NetworkManager.service

systemctl disable systemd-networkd.service
systemctl stop systemd-networkd.service 


systemd-resolve --interface=wlan0 --set-dns 1.1.1.1

resolvectl status

#echo -e "Adding IPTABLES rules..."


#current interface 
#/etc/systemd/network/20-wlan.network 

#drop ins:
#/etc/systemd/resolved.conf.d/dns_servers.conf
#/etc/NetworkManager/conf.d/dns.conf

#chattr -i /etc/resolv.conf
#ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf