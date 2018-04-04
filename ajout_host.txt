#!/bin/bash
read -p 'Entrez le nom du poste que vous voulez ajouter : ' nom
read -p 'Entrez l adresse IP du poste que vous voulez ajouter : ' ip

nomentite=`cat /etc/shinken/nom`
sudo touch /etc/shinken/hosts/$nom.cfg
sudo cat > /etc/shinken/hosts/$nom.cfg << EOF

define host{
    use             windows
    host_name       $nom-$nomentite
    address         $ip
    realm           $nomentite
}

EOF

sudo systemctl restart shinken
