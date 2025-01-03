#!/bin/bash

# Загрузка конфигурационных переменных
source /root/cisco.conf

# Установка необходимых пакетов
sudo apt-get update
sudo apt-get install -y git sshpass rsyslog

# Разкомментирование строк в rsyslog.conf
if ! grep -q '^module(load="imudp")' /etc/rsyslog.conf; then
    sudo sed -i 's|#module(load="imudp")|module(load="imudp")|' /etc/rsyslog.conf
fi
if ! grep -q '^input(type="imudp" port="514")' /etc/rsyslog.conf; then
    sudo sed -i 's|#input(type="imudp" port="514")|input(type="imudp" port="514")|' /etc/rsyslog.conf
fi

# Настройка конфигурации rsyslog
if ! grep -q "$LOG_FILE" /etc/rsyslog.conf; then
    echo ":hostname, !isequal, \"localhost\" $LOG_FILE" | sudo tee -a /etc/rsyslog.conf
    echo "& stop" | sudo tee -a /etc/rsyslog.conf
    sudo systemctl restart rsyslog
fi

# Настройка git
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# Инициализация TFTP_DIR как git репозитория
if [ ! -d "$TFTP_DIR/.git" ]; then
    cd $TFTP_DIR
    git init
    git add .
    git commit -m "Initial commit"
fi

# Создание директории .ssh и добавление файла config
mkdir -p ~/.ssh
cat <<EOT > ~/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    User root

Host *
    KexAlgorithms +diffie-hellman-group1-sha1
    HostKeyAlgorithms +ssh-rsa
    Ciphers +aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc
    MACs +hmac-sha1,hmac-sha1-96,hmac-md5,hmac-md5-96
EOT

# Установка правильных прав на директорию и файл .ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config

