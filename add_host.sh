#!/bin/bash
read -p 'Entrez le nom du poste que vous voulez ajouter : ' nom
read -p 'Entrez l adresse IP ou le nom FQDN du poste que vous voulez ajouter : ' ip

nomentite=`cat /etc/shinken/nom`
sudo touch /etc/shinken/hosts/$nom.cfg
sudo cat > /etc/shinken/hosts/$nom.cfg << EOF

define host{
    use             generic-host
    host_name       $nom-$nomentite
    address        $ip
    realm           $nomentite
}
define service {
    service_description     CPU Usage
        host_name       $nom-$nomentite
    check_command           check_ncpa!-t 'zenadmin' -P 5693 -M cpu/percent -w 80 -c 90 -q 'aggregate=avg'
    max_check_attempts      5
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   1440
    notification_period     24x7
    register                1
}

define service {
    service_description     Memory Usage
        host_name       $nom-$nomentite
    check_command           check_ncpa!-t 'zenadmin' -P 5693 -M memory/virtual -w 80 -c 90 -u G
    max_check_attempts      5
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   1440
    notification_period     24x7
     register                1
}

define service {
    service_description     Disk Usage
        host_name       $nom-$nomentite
    check_command           check_ncpa!-t 'zenadmin' -M 'disk/logical/C:|/free' --warning 25: --critical 10: -u G
    max_check_attempts      5
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   1440
    notification_period     24x7
    register                1
}
EOF

sudo systemctl restart shinken
