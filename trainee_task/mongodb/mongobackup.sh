#Step 1 : ++++++++++
#installing Mongodb
<<comment
#Follow below three step to install mongodb in Ubuntu system .
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

#Installing offical mongodb pacakage 
sudo apt-get install -y mongodb-org
systemctl start mongod.service

#Allow owner-ship of mongodb user to below two folder .
sudo chown -R mongodb:mongodb /var/lib/mongodb
sudo chown -R mongodb:mongodb /var/log/mongodb
comment

<<comment
#if authorization is enabled then we have to do auth at evry time when open mongo shell , for this problem we create user and do authentication 
#step below use for create user 

# If we want check user exist or not then use below two command 
#-------
#check testuser exsist or not , If not then create user (testuser)
x=`mongo --quiet --authenticationDatabase admin -u testuser -p myNewPassword --eval 'db.runCommand({ usersInfo: { user: "testuser", db: "admin" } }).users.length == 1'`
echo $x
#-------

#Step for create user: -----
sudo sed -i 's/authorization: "enabled"/authorization: "disabled"/g' /etc/mongod.conf
sytemctl restart mongod.service
mongo<<EOF
use admin
db.createUser({ user: "testuser", pwd: "myNewPassword",roles: [ { role: "userAdminAnyDatabase", db: "admin" } , "readWriteAnyDatabase"]})
db.auth('testuser','myNewPassword')
quit()
EOF
sudo sed -i 's/authorization: "disabled"/authorization: "enabled"/g' /etc/mongod.conf
sytemctl restart mongod.service
#-----------
comment

#create daatabse and tabled inside mongodb
mongo<<EOF
use admin
db.auth('testuser','myNewPassword')
use test
db.createCollection('test')
db.test.insertMany([{name:"mihir",course:"IT"},{name:"MIT"},{name:"jacson",course:"Comp"}])
EOF

#step 2 : ++++++++++

#backup the data into /tmp folder
mongodump -u testuser -p myNewPassword --authenticationDatabase admin -d test -o /tmp

#step 3 and 4 : ++++++++++ 

#move backupfile from /tmp folder to /var/backup folder

if [ -d /var/backup ]; then 
	echo ""
else 
     sudo mkdir /var/backup
fi

#this if condition check that date folder already exist or not , if exisr then delete this folder .
if [ ! -d /var/backup/test_datbase-`date +'%Y-%m-%d'` ]; then
       sudo mkdir /var/backup/test_datbase-`date +'%Y-%m-%d'`
else
	sudo rm -r /var/backup/test_datbase-`date +'%Y-%m-%d'`
	sudo mkdir /var/backup/test_datbase-`date +'%Y-%m-%d'`
fi

#backup the file from /tmp folder to /var/backup folder .
sudo mv /tmp/test/ /var/backup/test_datbase-`date +'%Y-%m-%d'` 


#Step 5 : +++++++++++
#Run this script every day at 11AM . 
#0 11 * * *  /bin/bash /home/mihirpatel/Desktop/day_2_feb/mongo.sh >> sudo crontab -e

<<comment
Comman error occuring at start mongodb
If mongod.service can not find then create own service named “mongod.service”
Step 1: vim  /etc/systemd/system/mongod.service
[Unit]
Description=An object/document-oriented database
After=network.target

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongodb.conf

[Install]
WantedBy=multi-user.target
Step 2: sudo systemctl daemon-relaod
Step 3: sudo systemctl start mongodb.servicce
Step 4: sudo systemctl status mongodb.service
comment
