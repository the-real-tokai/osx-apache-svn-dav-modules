# BuildSubversionDAVModules.sh

## Synopsis

The script builds matching `mod_auth_svn.so` and `mod_dav_svn.so` for
Mac OS X 10.10 (Yosemite) and Xcode 6 for use with Apache's httpd. For some reason Apple doesn't
manage anymore to bundle this both files somewhere in their releases, but they are required to set up
Subversion repository access via http and/or https.

## Usage of the Script

Download the [script](https://raw.githubusercontent.com/the-real-tokai/osx-apache-svn-dav-modules/master/BuildSubversionDAVModules.sh) and run it at the command line (Terminal):

	$ curl https://raw.githubusercontent.com/the-real-tokai/osx-apache-svn-dav-modules/master/BuildSubversionDAVModules.sh > BuildSubversionDAVModules.sh
	$ chmod +x ./BuildSubversionDAVModules.sh
	$ ./BuildSubversionDAVModules.sh

Assuming everything goes well the script creates the files `mod_auth_svn.so` and `mod_dav_svn.so` in the current directory.

## Requirements

* Mac OS X 10.10.x (Yosemite)
* Xcode 6.x (installed via the Mac OS X App Store)

Note: might work with older releases like Mac OS X 10.9 too (not tested)

## Installation of the Modules

The created modules can be used directly with Apache's httpd (as provided by Apple), f.ex.:

	$ sudo mkdir -p /usr/local/libexec/apache2/
	$ sudo cp mod_dav_svn.so /usr/local/libexec/apache2/
	$ sudo cp mod_authz_svn.so /usr/local/libexec/apache2/
	
In `/etc/apache2/other/` a `subversion.conf` similar to this needs to be created:

	LoadModule dav_svn_module     /usr/local/libexec/apache2/mod_dav_svn.so
	LoadModule authz_svn_module   /usr/local/libexec/apache2/mod_authz_svn.so

	<Location /repositories>
		DAV svn 
		SVNParentPath /Volumes/Data/Repositories
		SVNListParentPath on
	
		<RequireAll>
			# Allow access only from local network.
			Require local
			# Requires correct user(s)
			#Require user tokai
		</RequireAll>

		# Require secure connection
		#SSLRequireSSL
	
		# Password protection
		#
		#AuthType Basic
		#AuthName "Subversion Repositories"
		#AuthUserFile /etc/apache2/other/subversion.htpasswd
	</Location>

The main `httpd.conf` needs to be edited too, to make sure required modules, like `dav_module`, are loaded. Just uncomment the respective line(s). Finally the httpd server can be restarted:

	$ sudo apachectl restart
	
