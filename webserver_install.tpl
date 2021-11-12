#!/bin/bash

webserver=${app}

case $webserver in
    "nginx")
        sudo apt-get -y update
        sudo apt-get -y install nginx
        sudo service nginx start
        ;;
    "apache")
        sudo apt-get -y update
        sudo apt-get -y install apache2
        sudo service apache2 start
        ;;
esac
