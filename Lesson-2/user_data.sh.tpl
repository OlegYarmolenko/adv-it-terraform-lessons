#!/bin/bash
yum -y update
yum -y install httpd

cat <<EOF > /var/www/html/index.html
<html>
<h3>Build with Terraform</h3><br>

<h4>Owner ${f_name} ${l_name}</h4><br>

%{ for x in names ~}
Hello to ${x} from ${f_name}<br>
%{ endfor ~}

</html>
EOF

sudo service httpd start
chkconfig httpd on


