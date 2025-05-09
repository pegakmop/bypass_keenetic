#!/bin/sh

cat /dev/null > /opt/etc/unblock.dnsmasq

while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue
  echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue

  host=$(echo "${line}" | sed 's/^.*\.\(.*\.\w\{2,6\}\)$/\1/')
  if echo "${host}" | grep -q '\*' ; then
    host=$(echo "${host}" | sed 's/\*//;')
    echo "ipset=/*.${host}/unblocksh" >> /opt/etc/unblock.dnsmasq
    echo "server=/*.${host}/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq
    echo "ipset=/${host}/unblocksh" >> /opt/etc/unblock.dnsmasq
    echo "server=/${host}/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq
  else
    echo "ipset=/$line/unblocksh" >> /opt/etc/unblock.dnsmasq
    echo "server=/$line/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq
  fi
done < /opt/etc/unblock/shadowsocks.txt


while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue
  echo $line | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue
  echo "ipset=/$line/unblocktor" >> /opt/etc/unblock.dnsmasq
  echo "server=/$line/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq
done < /opt/etc/unblock/tor.txt


while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue
  echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue
  echo "ipset=/$line/unblockvless" >> /opt/etc/unblock.dnsmasq
  echo "server=/$line/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq
done < /opt/etc/unblock/vless.txt


while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue
  echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue
  echo "ipset=/$line/unblocktroj" >> /opt/etc/unblock.dnsmasq
  echo "server=/$line/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq
done < /opt/etc/unblock/trojan.txt

if ls -d /opt/etc/unblock/vpn-*.txt >/dev/null 2>&1; then
for vpn_file_names in /opt/etc/unblock/vpn-*; do
  vpn_file_name=$(echo "$vpn_file_names" | awk -F '/' '{print $5}' | sed 's/.txt//')
  unblockvpn=$(echo unblock"$vpn_file_name")
  cat "$vpn_file_names" | while read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    [ "${line#?}" = "#" ] && continue
    echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue
    echo "ipset=/$line/$unblockvpn" >> /opt/etc/unblock.dnsmasq
    echo "server=/$line/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq
  done
done
fi
