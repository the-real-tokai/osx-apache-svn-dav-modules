#!/bin/bash

# 
#  BuildSubversionDAVModules.sh v2
#  by tokai (http://tokai.binaryriot.org/), 20-Sep-2015 
#
#  Synopsis: This script builds matching 'mod_auth_svn.so' and 'mod_dav_svn.so' for Mac OS X 10.10 (Yosemite)
#            and Xcode 7 for use with Apache's httpd. For some reason Apple doesn't manage it anymore to bundle
#            the modules somewhere in their releases. Still both modules are required to set up Subversion
#            repository access via http and/or https.
#
#  Website:  https://github.com/the-real-tokai/osx-apache-svn-dav-modules
#
#  $Id$
#

set -ue


SDKPATH=$(xcrun --show-sdk-path)


# Check if "/usr/include" exists…
#
echo 'Checking for "/usr/include"…'
if [ ! -d "/usr/include" ]; then
	printf 'Warning: "/usr/include" is required to build Apache Subversion properly. Make sure that Xcode is installed. '
	printf 'In some cases it can be useful to additionally install the Xcode Command Line Tools (CLT) with "xcode-select --install" or manually '
	printf 'setting up "/usr/include" as a softlink pointing to "%s".\n' $SDKPATH
fi


# Grab the exact version of svnadmin…
# (assumes it is in the format of "version.revision.subrevision")
#
echo 'Checking version of "svnadmin"…'
svnadmin_version=`svnadmin --version | sed -n 's/^svnadmin, version \([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\) .*$/\1/p'`

if [ -z "svnadmin_version" ]; then
	echo 'Error: failed to grab version of "svnadmin".'
	exit 1
fi


# Fetch a matching version from the Apache servers and unpack it…
#
echo 'Downloading "subversion-'$svnadmin_version'.tar.bz2"…'
curl 'http://archive.apache.org/dist/subversion/subversion-'$svnadmin_version'.tar.bz2' > 'subversion-'$svnadmin_version'.tar.bz2'
echo 'Unpacking source code…'
tar -xvyf 'subversion-'$svnadmin_version'.tar.bz2'


( if cd "subversion-$svnadmin_version" ; then

	# Build the two Apache modules…
	#
	# Note: The build system is a broken disaster (perhaps related to invalid paths provided by OS X's
	#       "apr-1-config" and "apu-1-config"?), so let's try our best by tweaking the include paths, etc.,
	#       manually in case "/usr/include" is missing (which is the default situation on most OS X
	#       installations.)
	#	
	IFLAGS="-I$SDKPATH/usr/include -I$SDKPATH/usr/include/apr-1 -I$SDKPATH/usr/include/apache2"
	
	echo 'Configuring Subversion build…'
	./configure \
		--prefix=/Applications/Xcode.app/Contents/Developer/usr \
		--disable-debug \
		--with-zlib=/usr \
		--disable-mod-activation \
		--with-apache-libexecdir=$(/usr/sbin/apxs -q libexecdir) \
		--without-berkeley-db \
		--disable-nls \
		--without-serf \
		--with-apr=/usr \
		--with-apr-util=/usr \
		--with-apxs=no \
		CFLAGS="$IFLAGS" CXXFLAGS="$IFLAGS" CPPFLAGS="$IFLAGS" 
	
	echo 'Making modules…'
	make mod_dav_svn mod_authz_svn

else
	echo 'Error: Could not locate Apache Subversion source code.'
	exit 1
fi )


#  Dump used libs…
#
otool -L "subversion-${svnadmin_version}/subversion/mod_dav_svn/.libs/mod_dav_svn.so"
otool -L "subversion-${svnadmin_version}/subversion/mod_authz_svn/.libs/mod_authz_svn.so"


#  Clean up…
#
echo 'Copying modules to current directory…'
mv "subversion-${svnadmin_version}/subversion/mod_dav_svn/.libs/mod_dav_svn.so" './mod_dav_svn.so'
mv "subversion-${svnadmin_version}/subversion/mod_authz_svn/.libs/mod_authz_svn.so" './mod_authz_svn.so'


echo 'Deleting temporary files…'
rm -rf "subversion-${svnadmin_version}"
rm -f "subversion-${svnadmin_version}.tar.bz2"


printf '\n\nAll done!\n'


exit 0
