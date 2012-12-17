#!/bin/bash
# Author	: Yashodhan S Kulkarni
# Email		: yashodhan@securiace.com
# URL		: http://www.securiace.com
# Twitter	: http://twitter.com/yashodhan
ERPPATH="/var/www/erp.elexion.in"
ERPHOST="erp.elexion.in"
ERPSETUP="https://raw.github.com/gist/3817923/94eb18db9f8f882ffefe4e0aefca0b8c28e9aca0/install_erpnext.py"
clear
if [[ $EUID -ne 0 ]]; then
echo "You must be a root user to complete Installation" 2>&1
exit 100
else

# capture CTRL+C, CTRL+Z and quit singles using the trap
trap 'echo "Control-C disabled."' SIGINT
trap 'echo "Cannot terminate this script."'  SIGQUIT
trap 'echo "Control-Z disabled."' SIGTSTP

# ----------------------------------
# Step #2: User defined function
# ----------------------------------
pause() {
echo "------------------------------------------------------------"
read -p "Press [Enter] key to continue..." fackEnterKey
}

AutomaticSetup() {
echo "AutomaticSetup() called"
pause
apt-get -y update && apt-get -y upgrade
apt-get -y install screen git-core wget zip unzip iftop xclip dos2unix
apt-get -y install apache2
echo
echo "==================== Installing MySQL Server ===================="
echo "Keep your MySQL root password safe & handy"
echo
apt-get -y install mysql-server
pause
echo
echo "==================== Starting MySQL Secure Installation Script ===================="
echo
mysql_secure_installation --norootpw --yes
echo
echo "==================== Installing Python Libs and ERPNext Prerequisites ===================="
echo
pause
apt-get -y install libmysqlclient-dev
apt-get -y install python python-dev
apt-get -y install python-mysqldb
apt-get -y install python-setuptools python-pip
apt-get -y install memcached
pip install pytz
pip install --upgrade python-dateutil
pip install jinja2
pip install markdown2
pip install termcolor
pip install dateutil
pip install python-memcached
echo
echo "==================== Installing ERPNext ===================="
echo
pause
a2enmod rewrite
mkdir -p $ERPPATH
cd $ERPPATH
wget --no-check-certificate $ERPSETUP
python $ERPPATH/install_erpnext.py
	chown -R www-data:www-data *
#rm install_erpnext.py
echo
echo "==================== Updating Apache Configuration for ERPNext ===================="
echo
pause
(echo "# content of httpd.conf
SetEnv PYTHON_EGG_CACHE /var/tmp

Listen 80
NameVirtualHost *:80
<VirtualHost *:80>
ServerName erp.elexion.in
DocumentRoot "$ERPPATH"/public/
AddHandler cgi-script .cgi .xml .py

<Directory "$ERPPATH"/public/>
# directory specific options
Options -Indexes +FollowSymLinks +ExecCGI

# directory's index file
DirectoryIndex web.py

# rewrite rule
RewriteEngine on

# condition 1:
# ignore login-page.html, app.html, blank.html, unsupported.html
RewriteCond %{REQUEST_URI} ^((?!app\.html|blank\.html|unsupported\.html).)*$

# condition 2: if there are no slashes
# and file is .html or does not containt a .
RewriteCond %{REQUEST_URI} ^(?!.+/)((.+\.html)|([^.]+))$

# rewrite if both of the above conditions are true
RewriteRule ^(.+)$ web.py?page=$1 [NC,L]

AllowOverride all
Order Allow,Deny
Allow from all
</Directory>
</VirtualHost>" > /etc/apache2/sites-enabled/$ERPHOST.conf) | uniq -
echo
echo "==================== Creating cron for ERPNext ===================="
echo
pause
(crontab -l ; echo "*/3 * * * * cd /var/www/"$ERPHOST" && python lib/wnf.py --run_scheduler >> /var/log/erpnext-sch.log 2>&1") | uniq - | crontab -
pause
python $ERPPATH/lib/wnf.py --domain $ERPHOST
echo
echo
echo "==================== Installtion of ERPNext is Completed! ===================="
echo
echo
service apache2 reload
service apache2 restart
pause

}

# do something in two()
ManualSetup() {
clear
echo "ManualSetup() called"
pause
}

# function to display menus
show_menus() {
clear
echo "~~~~~~~~~~~~~~~~~~~~~"
echo "  ERPNext Installer  "
echo "~~~~~~~~~~~~~~~~~~~~~"
echo
echo "# Author	: Yashodhan S Kulkarni"
echo "# Email		: yashodhan@securiace.com"
echo "# URL		: http://www.securiace.com"
echo "# Twitter	: http://twitter.com/yashodhan"
echo
echo "------------------------------------------------"
echo "1. Perform Automatic Setup for ERPNext"
echo "2. Manual Setup (Not implemented yet!)"
echo "3. Exit"
echo "------------------------------------------------"
}

# read input from the keyboard and take a action
read_options() {
local choice
read -p "Enter choice [ 1 - 3] " choice
case $choice in
1) AutomaticSetup ;;
2) ManualSetup ;;
3) exit 0;;
*) echo -e "${RED}Error...${STD}" && sleep 2
esac
}

# -----------------------------------
# Step #4: Main logic - infinite loop
# ------------------------------------
while true
do
show_menus
read_options
done
fi