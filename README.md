# Shinken

sudo chmod o+x *.sh




define realm {
 realm_name       All
 realm_members    Bureau
 default          1    ;Is the default realm. Should be unique!
}

define realm{
 realm_name       Bureau
}



define poller{
poller_name poller-Bureau
address 10.8.0.3
port 7771
realm Bureau
spare 0
}

define scheduler{
scheduler_name scheduler-Bureau
address 10.8.0.3
port 7768
realm Bureau
spare 0
}
