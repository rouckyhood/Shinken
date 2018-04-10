#!/bin/bash
read -p 'Entrez le nom de l imprimante que vous voulez ajouter : ' nom
read -p 'Entrez l adresse IP du poste que vous voulez ajouter : ' ip

nomentite=`cat /etc/shinken/nom`
sudo touch /etc/shinken/hosts/$nom.cfg
sudo cat > /etc/shinken/hosts/$nom.cfg << EOF

define host{
    use             generic-service
    host_name       $nom-$nomentite
    address         $ip
    realm           $nomentite
}
define service{
    use                   generic-host
    host_name             $nom-$nomentite
    service_description   Status
    check_command         check_hpjd
    normal_check_interval 3
    retry_check_interval  1
}

EOF

sudo systemctl restart shinken
