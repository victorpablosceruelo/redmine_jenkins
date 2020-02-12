#!/bin/bash

http_proxy=http://10.254.250.94:3128/
https_proxy=http://10.254.250.94:3128/


pushd /var/www/redmine-4.0/plugins/redmine_jenkins

http_proxy=http://10.254.250.94:3128/ https_proxy=http://10.254.250.94:3128/ bundle update 
http_proxy=http://10.254.250.94:3128/ https_proxy=http://10.254.250.94:3128/ bundle install

popd

pushd /var/www/redmine-4.0/

http_proxy=http://10.254.250.94:3128/ https_proxy=http://10.254.250.94:3128/ bundle update 
http_proxy=http://10.254.250.94:3128/ https_proxy=http://10.254.250.94:3128/ bundle install

popd

echo "Restarting httpd..."

systemctl stop httpd 
systemctl start httpd

systemctl status httpd

echo " "
echo " "
echo "tail -f -n 100 /var/log/httpd/error_log /var/www/redmine-4.0/log/production.log"
echo " "
echo " "

tail -f -n 100 /var/log/httpd/error_log /var/www/redmine-4.0/log/production.log

