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
MYSQL_HOST=mysql.devopsdaws.online

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

dnf install maven -y &>> $LOGS_FILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $? "Creating System User"
else
    echo -e "Roboshop user already exists... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating App Directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading Shipping Code"

cd /app 
VALIDATE $? "Moving to App Directory"

rm -rf /app/* # It removes all the content which is present in that folder
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>> $LOGS_FILE
VALIDATE $? "Unzip Shipping Code"

cd /app 
mvn clean package &>> $LOGS_FILE
VALIDATE $? "Installing and Building Shipping"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving and Renaming Shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Created systemctl service"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "Installing MySQL"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql

systemctl enable shipping &>> $LOGS_FILE 
systemctl start shipping
VALIDATE $? "Enabling and Starting Shipping"