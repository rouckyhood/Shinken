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
    use                   generic-service        ; Inherit values from a template
    host_name             $nom-$nomentite             ; The name of the host the service is associated with
    service_description   Status         ; The service description
    check_command         check_hpjd   ; The command used to monitor the service
    normal_check_interval 10  ; Check the service every 10 minutes under normal conditions
    retry_check_interval  1   ; Re-check the service every minute until its final/hard state is determined
}

EOF

sudo systemctl restart shinken
