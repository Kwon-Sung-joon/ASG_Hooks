Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0
--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"
#cloud-config
cloud_final_modules:
- [scripts-user, always]
--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"
#!/bin/bash

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

function set_host {
    IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 | cut -d '.' -f 1,2,3,4 | sed 's/\./-/g')
    HOST=$(curl -s 169.254.169.254/latest/meta-data/tags/instance/GROUP)
    INSTANCE_ID=$(curl -s 169.254.169.254/latest/meta-data/instance-id)
    hostnamectl set-hostname $HOST-$IP --static
    echo "hostname changed to $HOST-$IP"
    su ec2-user -c '/bin/aws ec2 create-tags --resources '$INSTANCE_ID' --tags Key=\"Name\",Value=$(hostname) --region ap-northeast-2'
}

sed -i '$ s/$/\nmonitoring_group_type=HTL-htlprice/g' /app/scouter/agent.host/conf/scouter.conf
sed -i '61s/export/#export/g' /app/servers/HtlPrice-B/env.sh
sed -i '64s/#//g' /app/servers/HtlPrice-B/env.sh
set_host
