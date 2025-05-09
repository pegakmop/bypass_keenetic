#!/bin/sh

TAG="100-unblock-vpn.sh"

sleep 1
vpn_services="IKE|SSTP|OpenVPN|Wireguard|VPNL2TP"
vpn_check=$(curl -s localhost:79/rci/show/interface | grep -E "$vpn_services" | grep id | awk '{print $2}' | tr -d \", | uniq -u)

mkdir -p /opt/etc/iproute2
touch /opt/etc/iproute2/rt_tables
chmod 755 /opt/etc/iproute2/rt_tables

for vpn in $vpn_check; do
    if [ "$1" = "hook" ] && [ "$change" = "link" ] && [ "$id" = "$vpn" ]; then
        vpn_table=$(echo "$vpn" | tr [:upper:] [:lower:])

        if grep -q "$vpn_table" /opt/etc/iproute2/rt_tables; then
            echo "Таблица уже есть"
        else
            echo "Таблицы нет, создаем"
            get_last_fwmark_id=$(tail -1 /opt/etc/iproute2/rt_tables | awk '{print $1}')
            if [ -n "$get_last_fwmark_id" ]; then
                counter_new=$(($get_last_fwmark_id + 1))
            else
                counter_new=$((1000 + 1))
            fi
            vpn_table_file=$(echo "$counter_new" "$vpn_table")
            echo "$vpn_table_file" >> /opt/etc/iproute2/rt_tables
        fi

        sleep 1
        get_fwmark_id=$(grep "$vpn_table" /opt/etc/iproute2/rt_tables | awk '{print "0xd"$1}')

        case ${id}-${change}-${connected}-${link}-${up} in
            ${id}-link-no-down-down)
                info=$(echo VPN "$vpn" OFF: правила обновлены)
                logger -t "$TAG" "$info"
                ip rule del from all table "$vpn_table" priority 1778 2>/dev/null
                ip -4 rule del fwmark "$get_fwmark_id" lookup "$vpn_table" priority 1778 2>/dev/null
                ip -4 route flush table "$vpn_table"
                type=iptable table=nat /opt/etc/ndm/netfilter.d/100-redirect.sh
                ;;
            ${id}-link-yes-up-up)
                sleep 2
                vpn_ip=$(curl -s localhost:79/rci/show/interface/"$vpn"/address | tr -d \")
                vpn_type=$(ifconfig | grep "$vpn_ip" -B1 | head -1 | cut -d " " -f1)
                vpn_name=$(curl -s localhost:79/rci/show/interface/"$vpn"/description | tr -d \")
                unblockvpn=$(echo unblockvpn-"$vpn_name"-"$vpn")

                ip -4 route add table "$vpn_table" default via "$vpn_ip" dev "$vpn_type" 2>/dev/null
                ip -4 route show table main | grep -Ev ^default | while read -r ROUTE; do
                    ip -4 route add table "$vpn_table" "$ROUTE" 2>/dev/null
                done
                ip -4 rule add fwmark "$get_fwmark_id" lookup "$vpn_table" priority 1778 2>/dev/null
                ip -4 route flush cache
                touch /opt/etc/unblock/vpn-"$vpn_name"-"$vpn".txt
                chmod 0644 /opt/etc/unblock/vpn-"$vpn_name"-"$vpn".txt

                info=$(echo VPN "$vpn" ON: "$vpn_name" "$vpn_ip" via "$vpn_type")
                logger -t "$TAG" "$info"

                if iptables-save 2>/dev/null | grep -q "$unblockvpn"; then
                    info_ipset=$(echo "ipset уже есть")
                    logger -t "$TAG" "$info_ipset"
                else
                    ipset create "$unblockvpn" hash:net -exist
                fi
                type=iptable table=nat /opt/etc/ndm/netfilter.d/100-redirect.sh
                ;;
        esac
    fi
done

exit 0
