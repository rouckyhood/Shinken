#!/bin/bash

read -p 'Entrez le nom de l entité : ' nom
myip=$(ip route get 8.8.8.8 | sed -n '/src/{s/.*src *//p;q}')

## Mise à jour
sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove

## paquets nécessaire à l'install de Shinken
sudo apt-get install python-pip python-pycurl python-cherrypy3 nmap git -y
## création de l'utilisateur shinken
sudo useradd -m -s /bin/bash shinken
## install de Shinken
sudo pip install shinken

## droits sur dossiers pour Shinken
sudo chown -R shinken:shinken /var/lib/shinken
sudo chown -R shinken:shinken /var/log/shinken
sudo chown -R shinken:shinken /var/run/shinken

## initialiqation + install des modules
sudo shinken --init
sudo shinken install webui2
sudo shinken install npcdmod
sudo shinken install livestatus
sudo apt-get install mongodb -y
sudo pip install pymongo requests arrow bottle==0.12.8
sudo pip install alignak_backend_client
sudo pip install passlib
sudo sed -i -e 's/    modules/    modules webui2,livestatus,npcdmod/g' /etc/shinken/brokers/broker-master.cfg

## activation de Shinken au démarrage du système
sudo systemctl enable shinken-arbiter.service
sudo systemctl enable shinken-poller.service
sudo systemctl enable shinken-reactionner.service
sudo systemctl enable shinken-scheduler.service
sudo systemctl enable shinken-broker.service
sudo systemctl enable shinken-receiver.service
sudo systemctl enable shinken.service
sudo systemctl enable shinken.service
## démarrage de Shinken
sudo systemctl start shinken-arbiter.service
sudo systemctl start shinken-poller.service
sudo systemctl start shinken-reactionner.service
sudo systemctl start shinken-scheduler.service
sudo systemctl start shinken-broker.service
sudo systemctl start shinken-receiver.service
sudo systemctl start shinken.service

########

## install des paquets nécessaire aux plugins Nagios
sudo apt-get install autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext -y
## téléchargement des plugins Nagios
sudo wget http://www.nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz -O /tmp/nagios-plugins-2.2.1.tar.gz
cd /tmp/
sudo tar -xzvf nagios-plugins-2.2.1.tar.gz
## conpilation des plugins Nagios
cd nagios-plugins-2.2.1/
sudo ./configure --with-nagios-user=shinken --with-nagios-group=shinken
sudo make
sudo make install

## configuration du chemin pour l'uitlisation des plugins Nagios par Shinken
sudo sed -i '3d' /etc/shinken/resource.d/paths.cfg
sudo sed -i '3i$NAGIOSPLUGINSDIR$=/usr/local/nagios/libexec' /etc/shinken/resource.d/paths.cfg

## redémarrage de Shinken
sudo /etc/init.d/shinken restart

## téléchargement du check NCPA pour monitorer ordinateurs
## placement du check ncpa dans le répertoire approprié
cd /tmp
sudo wget https://assets.nagios.com/downloads/ncpa/check_ncpa.tar.gz
sudo tar xvf check_ncpa.tar.gz
sudo chown shinken:shinken check_ncpa.py
sudo chmod 775 check_ncpa.py
sudo mv check_ncpa.py /usr/local/nagios/libexec

## configuration de l'arbiter avec nom du royaume enfant
sudo sed -i '14d' /etc/shinken/arbiters/arbiter-master.cfg
sudo sed -i '14i    arbiter_name    arbiter-'$nom'' /etc/shinken/arbiters/arbiter-master.cfg

## configuration du scheduler avec nom du royaume enfant
sudo sed -i '15d' /etc/shinken/schedulers/scheduler-master.cfg
sudo sed -i '15i        scheduler_name      scheduler-'$nom'' /etc/shinken/schedulers/scheduler-master.cfg
sudo sed -i '38d' /etc/shinken/schedulers/scheduler-master.cfg
sudo sed -i '38i            realm  '$nom'' /etc/shinken/schedulers/scheduler-master.cfg

## configuration du poller avec nom du royaume enfant
sudo sed -i '10d' /etc/shinken/pollers/poller-master.cfg
sudo sed -i '10i            poller_name     poller-'$nom'' /etc/shinken/pollers/poller-master.cfg
sudo sed -i '50d' /etc/shinken/pollers/poller-master.cfg
sudo sed -i '50i            realm       '$nom'' /etc/shinken/pollers/poller-master.cfg

## configuration du broker avec nom du royaume enfant
sudo sed -i '16d' /etc/shinken/brokers/broker-master.cfg
sudo sed -i '16i                broker_name     broker-'$nom'' /etc/shinken/brokers/broker-master.cfg
sudo sed -i '48d' /etc/shinken/brokers/broker-master.cfg
sudo sed -i '48i            realm       '$nom'' /etc/shinken/brokers/broker-master.cfg

## configuration du reactionner avec nom du royaume enfant
sudo sed -i '10d' /etc/shinken/reactionners/reactionner-master.cfg
sudo sed -i '10i                reactionner_name    reactionner-'$nom'' /etc/shinken/reactionners/reactionner-master.cfg
sudo sed -i '38d' /etc/shinken/reactionners/reactionner-master.cfg
sudo sed -i '38i            realm       '$nom'' /etc/shinken/reactionners/reactionner-master.cfg

## configuration du royaume enfant faisant parti du royaume principal All
sudo sed -i '5d' /etc/shinken/realms/all.cfg 
sudo sed -i '5i realm_members    '$nom'' /etc/shinken/realms/all.cfg 
sudo echo "define realm{" >> /etc/shinken/realms/all.cfg 
sudo echo "realm_name       $nom" >> /etc/shinken/realms/all.cfg
sudo echo "default 1" >> /etc/shinken/realms/all.cfg
sudo echo "}" >> /etc/shinken/realms/all.cfg 

## configuration de l'host Rasperry Pi
sudo sed -i '4d' /etc/shinken/hosts/localhost.cfg
sudo sed -i '4i                host_name    Raspberry-'$nom'' /etc/shinken/hosts/localhost.cfg
sudo sed -i '5i                realm '$nom'' /etc/shinken/hosts/localhost.cfg
sudo sed -i '5i                _SNMPCOMMUNITY public' /etc/shinken/hosts/localhost.cfg

## ajout des services qui seront checker sur le Raspberry Pi
sudo cat >> /etc/shinken/hosts/localhost.cfg << EOF
define service {
 host_name Raspberry-$nom
 service_description Cpu
 check_command check_snmp_load!public!-f -w 3,3,2 -c 4,4,3 -T netsl
     normal_check_interval 3
    retry_check_interval  1
}
define service {
 host_name Raspberry-$nom
 service_description Disque
 check_command check_snmp_storage!public!-f -m / -r -w 80% -c 90%
     normal_check_interval 3
    retry_check_interval  1
}
define service {
 host_name Raspberry-$nom
 service_description Memoire
 check_command check_snmp_mem!public!-f -w 99,70 -c 100,85
     normal_check_interval 3
    retry_check_interval  1
}
EOF

## ajout de la commande pour les checks ordinateurs
sudo touch /etc/shinken/commands/check_ncpa.cfg
sudo cat > /etc/shinken/commands/check_ncpa.cfg << EOF
define command {
    command_name    check_ncpa
    command_line    \$USER1$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1$
}
EOF

## ajout de la commande pour les checks d'imprimantes
sudo touch /etc/shinken/commands/check_hpjd.cfg
sudo cat > /etc/shinken/commands/check_hpjd.cfg << EOF
define command {
    command_name   check_hpjd 
    command_line   \$USER1$/check_hpjd -H \$HOSTADDRESS$
}
EOF

## ajout de la commande pour les checks CPU du Raspberry Pi
sudo touch /etc/shinken/commands/check_snmp_load.cfg
sudo cat > /etc/shinken/commands/check_snmp_load.cfg << EOF
define command{
 command_name check_snmp_load
 command_line \$USER1$/check_snmp_load.pl -H \$HOSTADDRESS$ -C \$ARG1$ \$ARG2$
}
EOF

## ajout de la commande pour les checks disques du Raspberry Pi
sudo touch /etc/shinken/commands/check_snmp_storage.cfg
sudo cat > /etc/shinken/commands/check_snmp_storage.cfg << EOF
define command{
 command_name check_snmp_storage
 command_line \$USER1$/check_snmp_storage.pl -H \$HOSTADDRESS$ -C \$ARG1$ \$ARG2$
}
EOF

## ajout de la commande pour les checks mémoires du Raspberry Pi
sudo touch /etc/shinken/commands/check_snmp_mem.cfg
sudo cat > /etc/shinken/commands/check_snmp_mem.cfg << EOF
define command{
 command_name check_snmp_mem
 command_line \$USER1$/check_snmp_mem.pl -H \$HOSTADDRESS$ -C \$ARG1$ \$ARG2$
}
EOF

## sauvegarde du nom de l'entité qui servira pour les scripts d'install d'hôtes
touch /etc/shinken/nom
echo $nom >> /etc/shinken/nom

## installation de NPN4Nagios
sudo apt-get -y install apache2 php php-gd php-xml rrdtool librrds-perl snmp snmpd libpng-dev zlib1g-dev
sudo git clone https://github.com/lingej/pnp4nagios.git
cd pnp4nagios
sudo ./configure --enable-sockets --with-nagios-user=shinken --with-nagios-group=shinken  --with-httpd-conf=/etc/apache2/sites-available
sudo make all
sudo make fullinstall

## modif du fichier de configuration de PNP4Nagios pour qu'il fonctionne avec Shinken (suppression de l'authentification)
sudo sed -i '20d' /etc/httpd/conf.d/pnp4nagios.conf
sudo sed -i '20d' /etc/httpd/conf.d/pnp4nagios.conf
sudo sed -i '20d' /etc/httpd/conf.d/pnp4nagios.conf
sudo sed -i '20d' /etc/httpd/conf.d/pnp4nagios.conf

## configuration de NPN4Nagios (apache2)
sudo cp -a /etc/httpd/conf.d/pnp4nagios.conf /etc/apache2/sites-available/
sudo a2dissite 000-default.conf && sudo a2ensite pnp4nagios.conf && sudo a2enmod rewrite
sudo systemctl enable apache2
sudo systemctl start apache2
sudo mv /usr/local/pnp4nagios/share/install.php /usr/local/pnp4nagios/share/install.php.old

## installation des modules Shinken nécessaires pour PNP4Nagios
sudo shinken install npcdmod
sudo shinken install ui-pnp

## configuration de l'interface web de Shinken pour qu'elle ajoute les graph de PNP4Nagios
sudo sed -i '90d' /etc/shinken/modules/webui2.cfg
sudo sed -i '90i    modules  ui-pnp' /etc/shinken/modules/webui2.cfg

## téléchargement des checks SNMP
cd /usr/local/nagios/libexec
sudo wget http://nagios.manubulon.com/check_snmp_load.pl
sudo wget http://nagios.manubulon.com/check_snmp_mem.pl
sudo wget http://nagios.manubulon.com/check_snmp_storage.pl
sudo chmod 777 check_snmp_*.pl
## installation des plugins Nagios manquants pour les checks SNMP
sudo apt-get -y install nagios-plugins

## configuration du SNMP
sudo sed -i '15d' /etc/snmp/snmpd.conf
sudo sed -i '15i#agentAddress  udp:127.0.0.1:161' /etc/snmp/snmpd.conf
sudo sed -i '17iagentAddress udp:161' /etc/snmp/snmpd.conf
sudo sed -i '52d' /etc/snmp/snmpd.conf
sudo sed -i '52i#rocommunity public  default    -V systemonly' /etc/snmp/snmpd.conf
sudo sed -i '55irocommunity public localhost' /etc/snmp/snmpd.conf

## redémarrage des services
sudo /etc/init.d/npcd restart
sudo systemctl restart shinken-arbiter.service
sudo systemctl restart shinken-poller.service
sudo systemctl restart shinken-reactionner.service
sudo systemctl restart shinken-scheduler.service
sudo systemctl restart shinken-broker.service
sudo systemctl restart shinken-receiver.service
sudo systemctl restart shinken.service
sudo systemctl restart apache2
sudo systemctl restart snmpd

