#!/bin/bash

read -p 'Entrez le nom de l entité : ' nom

#sudo apt-get update -y
#sudo apt-get dist-upgrade -y
#sudo apt-get autoremove

sudo apt-get install python-pip python-pycurl python-cherrypy3 nmap git -y
sudo useradd -m -s /bin/bash shinken
sudo pip install shinken

sudo chown -R shinken:shinken /var/lib/shinken
sudo chown -R shinken:shinken /var/log/shinken
sudo chown -R shinken:shinken /var/run/shinken

sudo shinken --init
sudo shinken install webui2
sudo shinken install npcdmod
sudo shinken install livestatus
sudo apt-get install mongodb -y
sudo pip install pymongo requests arrow bottle==0.12.8
sudo sed -i -e 's/    modules/    modules webui2,livestatus,npcdmod/g' /etc/shinken/brokers/broker-master.cfg


sudo systemctl enable shinken-arbiter.service
sudo systemctl enable shinken-poller.service
sudo systemctl enable shinken-reactionner.service
sudo systemctl enable shinken-scheduler.service
sudo systemctl enable shinken-broker.service
sudo systemctl enable shinken-receiver.service
sudo systemctl enable shinken.service
sudo systemctl enable shinken.service
sudo systemctl start shinken-arbiter.service
sudo systemctl start shinken-poller.service
sudo systemctl start shinken-reactionner.service
sudo systemctl start shinken-scheduler.service
sudo systemctl start shinken-broker.service
sudo systemctl start shinken-receiver.service
sudo systemctl start shinken.service

########

sudo apt-get install autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext -y

sudo wget http://www.nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz -O /tmp/nagios-plugins-2.2.1.tar.gz
cd /tmp/
sudo tar -xzvf nagios-plugins-2.2.1.tar.gz
cd nagios-plugins-2.2.1/
sudo ./configure --with-nagios-user=shinken --with-nagios-group=shinken
sudo make
sudo make install

sudo sed -i '3d' /etc/shinken/resource.d/paths.cfg
sudo sed -i '3i$NAGIOSPLUGINSDIR$=/usr/local/nagios/libexec' /etc/shinken/resource.d/paths.cfg

sudo /etc/init.d/shinken restart

cd /tmp
sudo wget https://assets.nagios.com/downloads/ncpa/check_ncpa.tar.gz
sudo tar xvf check_ncpa.tar.gz
sudo chown shinken:shinken check_ncpa.py
sudo chmod 775 check_ncpa.py
sudo mv check_ncpa.py /usr/local/nagios/libexec

sudo sed -i '14d' /etc/shinken/arbiters/arbiter-master.cfg
sudo sed -i '14i    arbiter_name    arbiter-'$nom'' /etc/shinken/arbiters/arbiter-master.cfg

sudo sed -i '15d' /etc/shinken/schedulers/scheduler-master.cfg
sudo sed -i '15i        scheduler_name      scheduler-'$nom'' /etc/shinken/schedulers/scheduler-master.cfg
sudo sed -i '38d' /etc/shinken/schedulers/scheduler-master.cfg
sudo sed -i '38i            realm  '$nom'' /etc/shinken/schedulers/scheduler-master.cfg


sudo sed -i '10d' /etc/shinken/pollers/poller-master.cfg
sudo sed -i '10i            poller_name     poller-'$nom'' /etc/shinken/pollers/poller-master.cfg
sudo sed -i '50d' /etc/shinken/pollers/poller-master.cfg
sudo sed -i '50i            realm       '$nom'' /etc/shinken/pollers/poller-master.cfg

sudo sed -i '16d' /etc/shinken/brokers/broker-master.cfg
sudo sed -i '16i                broker_name     broker-'$nom'' /etc/shinken/brokers/broker-master.cfg
sudo sed -i '48d' /etc/shinken/brokers/broker-master.cfg
sudo sed -i '48i            realm       '$nom'' /etc/shinken/brokers/broker-master.cfg

sudo sed -i '10d' /etc/shinken/reactionners/reactionner-master.cfg
sudo sed -i '10i                reactionner_name    reactionner-'$nom'' /etc/shinken/reactionners/reactionner-master.cfg
sudo sed -i '38d' /etc/shinken/reactionners/reactionner-master.cfg
sudo sed -i '38i            realm       '$nom'' /etc/shinken/reactionners/reactionner-master.cfg


sudo sed -i '5d' /etc/shinken/realms/all.cfg 
sudo sed -i '5i realm_members    '$nom'' /etc/shinken/realms/all.cfg 
sudo echo "define realm{" >> /etc/shinken/realms/all.cfg 
sudo echo "realm_name       $nom" >> /etc/shinken/realms/all.cfg
sudo echo "default 1" >> /etc/shinken/realms/all.cfg
sudo echo "}" >> /etc/shinken/realms/all.cfg 

sudo sed -i '4d' /etc/shinken/hosts/localhost.cfg
sudo sed -i '4i                host_name    Raspberry-'$nom'' /etc/shinken/hosts/localhost.cfg
sudo sed -i '6i                realm '$nom'' /etc/shinken/hosts/localhost.cfg


sudo touch /etc/shinken/hostgroups/$nom.cfg
sudo cat > /etc/shinken/hostgroups/$nom.cfg << EOF
 define hostgroup{
    hostgroup_name      $nom
    alias               $nom
    members             *
}
define service {
    service_description     CPU Usage
    check_command           check_ncpa!-t 'zenadmin' -P 5693 -M cpu/percent -w 80 -c 90 -q 'aggregate=avg'
    max_check_attempts      5
    check_interval          5
    hostgroup_name          $nom
    host_name           !Raspberry-$nom
    retry_interval          1
    check_period            24x7
    notification_interval   60
    notification_period     24x7
    register                1
}

define service {
    service_description     Memory Usage
    check_command           check_ncpa!-t 'zenadmin' -P 5693 -M memory/virtual -w 80 -c 90 -u G
    max_check_attempts      5
    check_interval          5
    retry_interval          1
    check_period            24x7
    notification_interval   60
    hostgroup_name          $nom
    host_name           !Raspberry-$nom
    notification_period     24x7
     register                1
}

define service {
    service_description     Disk Usage
    check_command           check_ncpa!-t 'zenadmin' -M 'disk/logical/C:|/free' --warning 25: --critical 10: -u G
    max_check_attempts      5
    check_interval          5
    retry_interval          1
    hostgroup_name          $nom
    host_name           !Raspberry-$nom
    check_period            24x7
    notification_interval   60
    notification_period     24x7
    register                1
}
EOF

#!/bin/bash

sudo touch /etc/shinken/commands/check_ncpa.cfg
sudo cat > /etc/shinken/commands/check_ncpa.cfg << EOF
define command {
    command_name    check_ncpa
    command_line    \$USER1$/check_ncpa.py -H \$HOSTADDRESS$ \$ARG1$
}
EOF

touch /etc/shinken/nom
echo $nom >> /etc/shinken/nom

sudo systemctl restart shinken-arbiter.service
sudo systemctl restart shinken-poller.service
sudo systemctl restart shinken-reactionner.service
sudo systemctl restart shinken-scheduler.service
sudo systemctl restart shinken-broker.service
sudo systemctl restart shinken-receiver.service
sudo systemctl restart shinken.service
