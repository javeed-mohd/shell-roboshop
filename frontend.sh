#!/bin/bash

# To log files
USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop" # shell-roboshop --> folder name
LOGS_FILE="$LOGS_FOLDER/$0.log"  # $0=12-logs.sh(script name)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.devopsdaws.online

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

dnf module disable nginx -y &>> $LOGS_FILE
dnf module enable nginx:1.24 -y &>> $LOGS_FILE
dnf install nginx -y &>> $LOGS_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>> $LOGS_FILE
systemctl start nginx 
VALIDATE $? "Enabling and Starting Nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing Default Content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOGS_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>> $LOGS_FILE
VALIDATE $? "Downloaing and Unzipping Frontend"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied our nginx conf file"

systemctl restart nginx 
VALIDATE $? "Restarting Nginx"



