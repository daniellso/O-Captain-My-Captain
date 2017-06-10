#!/usr/bin/env bash
DB_PWD="ok1234"

if [ -e "/etc/django-provisioned" ];
then
    echo "django provisioning already completed. Skipping..."
    exit 0
else
    echo "Starting django provisioning process..."
    echo "--------------------------------------------------"
fi

function init_setting {
    sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime > /dev/null 2>&1
    sudo locale-gen ko_KR.UTF-8 > /dev/null 2>&1

    sudo cp /etc/apt/sources.list ~/sources.list.old > /dev/null 2>&1
    sudo sed -i 's/archive.ubuntu.com/ftp.daumkakao.com/g' /etc/apt/sources.list > /dev/null 2>&1

    sudo debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME"
    sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_PWD"
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_PWD"
}

function install_dep {
    # for mariadb
    sudo apt-get install software-properties-common > /dev/null 2>&1
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 > /dev/null 2>&1
    sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://ftp.utexas.edu/mariadb/repo/10.1/ubuntu xenial main' > /dev/null 2>&1

    sudo apt-add-repository -y ppa:chris-lea/uwsgi > /dev/null 2>&1
    sudo apt-get update > /dev/null 2>&1

    sudo apt-get -y upgrade > /dev/null 2>&1

    sudo apt-get install -y curl git htop sysstat tree ntp zip postfix nginx > /dev/null 2>&1
    sudo apt-get install -y build-essential libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev tk-dev libmariadbclient-dev > /dev/null 2>&1
    sudo apt-get install -y mariadb-server > /dev/null 2>&1
}

function ubuntu_service_restart {
    sudo sed -i 's/bind-address/# bind-address/g' /etc/mysql/my.cnf
    sudo sed -i 's/#sql_mode/sql_mode/g' /etc/mysql/my.cnf
    sudo sed -i 's/TRADITIONAL/NO_AUTO_CREATE_USER,STRICT_TRANS_TABLES/g' /etc/mysql/my.cnf

    sudo service postfix reload
    sudo service mysql restart
    sudo service ntp reload
    sudo service sysstat restart
}

function setup_mariadb {
    mysql -uroot -p$DB_PWD <<EOF
use mysql;
UPDATE user SET Host='%' WHERE User='root' AND Host='127.0.0.1';
CREATE DATABASE keating CHARACTER SET utf8 COLLATE utf8_general_ci;
EOF
}

function set_pyenv {
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
    echo 'eval "$(pyenv init -)"' >> ~/.profile
}

function install_python3 {
    ~/.pyenv/bin/pyenv install 3.6.1
    ~/.pyenv/bin/pyenv global 3.6.1
}

function set_pip_config {
    mkdir ~/.pip
    echo '[list]' >> ~/.pip/pip.conf
    echo 'format=columns' >> ~/.pip/pip.conf
}

function set_python_venv {
    mkdir ~/python-venv;cd ~/python-venv
    ~/.pyenv/versions/3.6.1/bin/python -m venv django
    echo 'source ~/python-venv/django/bin/activate' >> ~/.profile
}

function install_python_third_party {
    ~/python-venv/django/bin/pip install django mysqlclient
}

# set password
echo "ubuntu:ubuntu" | sudo chpasswd

init_setting
install_dep
setup_mariadb
ubuntu_service_restart
set_pyenv
install_python3
set_pip_config
set_python_venv
install_python_third_party

sudo touch /etc/django-provisioned

echo "------------------------------------------------------------------------------------"
echo ":::::::::::::::::::::::::: vagrant ssh or using putty ::::::::::::::::::::::::::::::"
echo "===================================================================================="
echo "vm address: 192.168.33.10, login id: ubuntu, password: ubuntu"
echo "===================================================================================="
echo "And enjoy~!"
