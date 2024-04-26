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
BUCKET='aws-code-deploy'
PREFIX='service'
ZIP_FILE='service.zip'
TOMCAT_DIR='/app/service'
REGION='ap-northeast-2'
ASG_NAME=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/aws:autoscaling:groupName)


function set_host {
    IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 | cut -d '.' -f 1,2,3,4 | sed 's/\./-/g')
    HOST=$(curl -s 169.254.169.254/latest/meta-data/tags/instance/GROUP)
    INSTANCE_ID=$(curl -s 169.254.169.254/latest/meta-data/instance-id)
    hostnamectl set-hostname $HOST-$IP --static
    echo "hostname changed to $HOST-$IP"
    su ec2-user -c '/bin/aws ec2 create-tags --resources '$INSTANCE_ID' --tags Key=\"Name\",Value=$(hostname) --region ap-northeast-2'
}

function src_cp {
    eTag=$(aws s3api get-object --bucket $BUCKET --key $PREFIX/$ZIP_FILE /tmp/$ZIP_FILE --output text | awk '{print $4}')
    echo "Copy $eTag"
    unzip /tmp/$ZIP_FILE ROOT.war -d /tmp/
    chmod 0664 /tmp/ROOT.war
    cp -R /tmp/ROOT.war $TOMCAT_DIR/webapps/ROOT.war
    chown -R tomcat: $TOMCAT_DIR/webapps/ROOT.war
}

function init_svc {
    #start was
    echo "Start WAS..."
    su tomcat -c ''$TOMCAT_DIR'/start.sh;'
    was_chk
}
function was_chk {
    while :
    do
        code=$(curl -L -k --connect-timeout 5 -so /dev/null -w '%{http_code}' http://localhost:8080)
        if [ $code -eq 200 ];
        then
            echo "WAS Health Check Succeed !!$code"
            return $code
        fi
            echo "WAS Health Check is $code ..."
            sleep 3
        done
}

function complete_lifecycle_action { 
    $(aws autoscaling complete-lifecycle-action \
      --lifecycle-hook-name Launch \
      --auto-scaling-group-name $ASG_NAME \
      --lifecycle-action-result CONTINUE \
      --instance-id $INSTANCE_ID \
      --region $REGION)
}


set_host
src_cp
init_svc
complete_lifecycle_action
