#!/bin/bash

# To log files
USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop" # shell-roboshop --> folder name
LOGS_FILE="$LOGS_FOLDER/$0.log"  # $0=12-logs.sh(script name)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1 
fi

mkdir -p $LOGS_FOLDER 

# By default shell will not execute this, only it will be executed when called (It can be validate, status_check...)
VALIDATE(){

    if [ $1 -ne 0 ]; then
        echo -e "$2... $R FAILURE $N" | tee -a $LOGS_FILE # Tee is used for showing the output both in terminal and file (logs_file)
        exit 1
    else 
        echo -e "$2... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi

}

dnf module disable redis -y &>> $LOGS_FILE
dnf module enable redis:7 -y &>> $LOGS_FILE
VALIDATE $? "Enabling Redis 7"

dnf install redis -y &>> $LOGS_FILE
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/c protected-mode no' /etc/redis/redis.conf # Here second e indicates extra parameters
VALIDATE $? "Allowing Remote Connections"

systemctl enable redis &>> $LOGS_FILE 
systemctl start redis 
VALIDATE $? "Enabling and Starting Redis"

