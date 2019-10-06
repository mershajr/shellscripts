#!/bin/bash

Log=/tmp/stack.log
ID=$(id -u)
Modjk_url=http://mirrors.estointernet.in/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz
Modjk_tarfile=$(echo $Modjk_url | awk -F / '{print $NF}')    #$(echo $Modjk_url | cut -d / -f8)
Modjk_pack=$(echo $Modjk_tarfile | sed -e 's/.tar.gz//')
Tomcat_url=http://apachemirror.wuchna.com/tomcat/tomcat-9/v9.0.26/bin/apache-tomcat-9.0.26.tar.gz
Tomcat_tarfile=$(echo $Tomcat_url | awk -F / '{print $NF}')
Tomcat_dir=$(echo $Tomcat_tarfile | sed -e 's/.tar.gz//')
Student_war=https://github.com/mershajr/Development-files/raw/master/APPSTACK/student.war
Mysql_connector=https://github.com/mershajr/Development-files/raw/master/APPSTACK/mysql-connector-java-5.1.40.jar
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
M="\e[35m"
C="\e[36m"
N="\e[0m"

#echo "checking the root user or not"

if [ $ID -ne 0 ]; then
     echo -e " $M you are not the root user and you dont have permissions to run this script $N"
	 exit 1
else
     echo -e "$Byou are the root user $N"
fi

validate(){
if [ $1 -ne 0 ]; then
    echo -e  "$2 ------- $R Failed $N"
	exit 1
else  
    echo -e "$2 ------- $G Success $N"

fi	
}

skip() {
  echo -e "$1 --- $Y skipping $N"
}
#echo "Installing the web server"
echo -e "$C Installing the HTTPD $N "
yum install httpd -y &>>$Log

validate $? "Installing the webserver"

#echo "Starting the webserver"

systemctl start httpd &>>$Log

validate $? "starting the webserver"

#mkdir TOMCAT
#cd TOMCAT
if [ -f /opt/$Modjk_tarfile ] ; then
     skip "modjk_tarfile already exists"
else	 
     wget $Modjk_url -O /opt/$Modjk_tarfile &>>$Log

     validate $? "Downloading the modjk.so"
fi

cd /opt

if [ -d /opt/$Modjk_pack ] ; then
      skip "modjk_package already exists"
else
      tar -xf $Modjk_tarfile &>>$Log

	  validate $? "Extracting the modjk.so"
fi

yum install gcc httpd-devel java -y &>>$Log

validate $? "Installing the gcc and httpd-devel and Java packages"

cd /opt/$Modjk_pack/native

./configure --with-apxs=/bin/apxs &>>$Log && make &>>$Log && make install &>>$Log

validate $? "configuing the modjk.so"

cd /etc/httpd/conf.d

if [ -f /etc/httpd/conf.d/modjk.conf ] ; then

		skip "modjk.conf already exists"
else
		echo 'LoadModule jk_module modules/mod_jk.so
		JkWorkersFile conf.d/workers.properties
		JkLogFile logs/mod_jk.log
		JkLogLevel info
		JkLogStampFormat "[%a %b %d %H:%M:%S %Y]"
		JkOptions +ForwardKeySize +ForwardURICompat -ForwardDirectories
		JkRequestLogFormat "%w %V %T"
		JkMount /student tomcatA
		JkMount /student/* tomcatA' > modjk.conf

		validate $? "creating the modjk.conf"
fi
cd /etc/httpd/conf.d

if [ -f /etc/httpd/conf.d/workers.properties ] ; then

		skip "workers.properties already exists"
else
		echo '### Define workers
		worker.list=tomcatA
		### Set properties
		worker.tomcatA.type=ajp13
		worker.tomcatA.host=localhost
		worker.tomcatA.port=8009' > workers.properties

		validate $? "creating the workers.properties"
fi
systemctl restart httpd &>>$Log

validate $? "Restarting the webserver"

echo -e "$C Installing the tomcat application $N "


if [ -f /opt/$Tomcat_tarfile ]; then

        skip "Tomcat package already availabale"
else 

     wget $Tomcat_url -O /opt/$Tomcat_tarfile &>>Log
	 validate $? "Downloading the tomcat tarfile"
fi

cd /opt

if [ -d /opt/$Tomcat_dir ] ; then
      skip "Tomccat directory already exists"
else
      tar -xf $Tomcat_tarfile &>>$Log

	  validate $? "Extracting the Tomcat directory"
fi

cd /opt/$Tomcat_dir/webapps



rm -rf *

validate $? "removing the old files"


wget $Student_war &>>Log

validate $? "downloading the student.war"

cd ../lib

if [ -f $Mysql_connector ]; then

        skip " mysql connector is already availabale"

else 

     wget $Mysql_connector &>>Log
	 validate $? "Downloading the mysql jar file"
fi


cd ../conf



sed -i -e '/TestDB/ d' context.xml

sed -i -e '$ i <Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource" maxTotal="100" maxIdle="30" maxWaitMillis="10000" username="student" password="student@1" driverClassName="com.mysql.jdbc.Driver" url="jdbc:mysql://localhost:3306/studentapp"/> ' context.xml

validate $? "updating the context.xml"

cd ../bin/


sh shutdown.sh &>>Log


sh startup.sh &>>Log

validate $? "Restarting the tomcat"

echo -e "$C Installing the mariadb-server $N "


yum install mariadb mariadb-server -y &>>Log

validate $? "Installing the databaserver"

systemctl start mariadb &>>Log

validate $? "starting the databaserver"

systemctl enable mariadb &>>Log

cd /opt 
		echo "create database if not exists studentapp;
    use studentapp;
    CREATE TABLE  if not exists Students(student_id INT NOT NULL AUTO_INCREMENT,
	student_name VARCHAR(100) NOT NULL,
    student_addr VARCHAR(100) NOT NULL,
	student_age VARCHAR(3) NOT NULL,
	student_qual VARCHAR(20) NOT NULL,
	student_percent VARCHAR(10) NOT NULL,
	student_year_passed VARCHAR(10) NOT NULL,
	PRIMARY KEY (student_id)
);
grant all privileges on studentapp.* to 'student'@'localhost' identified by 'student@1';" > student.sql

		validate $? "creating the student.sql file"

mysql < student.sql  &>>Log



systemctl restart mariadb &>>Log

validate $? "Restarting the mariadb"









	 
	 