#!/bin/bash

# Загрузка конфигурационных переменных
source /root/cisco.conf

# Проверка существования файла логов и создание его, если он не существует
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chown root:adm "$LOG_FILE"
    sudo systemctl restart rsyslog
fi

# Мониторинг логов и бэкап конфигурации
tail -F $LOG_FILE | while read LINE; do
    for SEARCH_STRING in "${SEARCH_STRINGS[@]}"; do
        if echo "$LINE" | grep -q "$SEARCH_STRING"; then
            DEVICE_NAME=$(echo $LINE | awk '{print $2}')
            echo "Backing up configuration for device: $DEVICE_NAME"
            
            sshpass -p $SSH_PASS ssh $DEVICE_NAME "sh run" > $TFTP_DIR/$DEVICE_NAME-running-config
            
            cd $TFTP_DIR
            git add .
            git commit -a -m "$(date '+%Y-%m-%d_%H:%M:%S')"
        fi
    done
done

