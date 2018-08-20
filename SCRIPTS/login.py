import os
import sys
import getopt
from selenium import webdriver

# Based:
#   * https://github.com/samvid25/Captive-Portal-Auto-Login
#   * MORE: https://github.com/search?q=automatic+login+captive+portal&type=Repositories

NAME = os.path.basename(__file__)

### VARS ###
login_url = "https://captive.wifigo.es/login.php?res=notyet&host=5D6A05BAE23D&client_mac=0C:8B:FD:B0:CD:36&client_ip=10.1.0.202&userurl=http://www.gstatic.com/generate_204&login_url=https://acceso.wifigo.es/login&error=&user="
username = "pepito.pepote.1@mailinator.com"
password = "peteWIFI"
# web
username_find_element_by_name = "username"
password_find_element_by_name = "password"
loginbutton_find_element_by_id = "loginbutton"



def print_help():
	print "To login into captive portals"
	print NAME + "" 
	print "    -l <url>			| --login-url=<url>			"
	print "    -u <username> 	| --user=<username>			"
	print "    -p <password> 	| --pass=<password>			"
	sys.exit(0)

def main(argv):

    global login_url
    global username
    global password

    try:
        opts, args = getopt.getopt(argv,"l:u:p",["login-url","user","pass"])
    except getopt.GetoptError:
		print "ERROR: in getopts"
		print_help()
		sys.exit(-1)

    for opt, arg in opts:
        if opt in ("-o", "--login-url"):
            login_url = arg
        elif opt in ("-d", "--user"):
            username = arg
        elif opt in ("-f", "--pass"):
            password = arg
        elif opt in ("-h", "--help"):
            print_help()
        else:
            print "arg not valid"

    if login_url=="" or username=="" or password=="":
        print "ERROR: login_url or username or password is empty"
        sys.exit(-1)

    driver = webdriver.Firefox()

    try: 
        driver.get(login_url)
    except:
        sys.exit(0)

    driver.find_element_by_name("Accede con WiFiGO").click()

    username = driver.find_element_by_name("username")
    username.clear()

    password = driver.find_element_by_name("password")
    password.clear()

    username.send_keys(username)
    password.send_keys(password)

    driver.find_element_by_id("loginbutton").click()

    print "Logged In."

    driver.close()



if __name__ == "__main__":
    main(sys.argv[1:])