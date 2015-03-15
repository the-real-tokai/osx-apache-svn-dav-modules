#!/bin/bash

# 
#  Synopsis: This script builds matching 'mod_auth_svn.so' and 'mod_dav_svn.so' for Mac OS X 10.10 (Yosemite)
#            and Xcode 6 for use with Apache's httpd. For some reason Apple doesn't manage anymore to bundle
#            this both files somewhere in their releases, but they are required to set up Subversion repository
#            access via http and/or https.
#
#  Quickly messed together by tokai, 15-Mar-2015.
#
#  https://github.com/the-real-tokai/osx-apache-svn-dav-modules
#  http://tokai.binaryriot.org/
#
#  $Id$
#

set -uex

# Check if "/usr/include" exists.
#
if [ ! -d "/usr/include" ]; then
	# Grab "version.revision" and skip ".subrevision"
	osx_version=`sw_vers -productVersion | sed -n 's/\(^[0-9]\{1,2\}\)\.\([0-9]\{1,2\}\).*$/\1.\2/p'`
		
	printf 'Error: "/usr/include" is required to build Apache Subversion. Make sure that Xcode is installed. '
	printf 'In case the directory is missing anyway then making it a softlink to "'
	printf '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX'$osx_version'.sdk/usr/include'
	printf '" will work too.\n'
	exit 1
fi

# Grab the exact version of svnadmin, assumes it is in the format of "version.revision.subrevision"
#
svnadmin_version=`svnadmin --version | sed -n 's/^svnadmin, version \([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\) .*$/\1/p'`

if [ -z "svnadmin_version" ]; then
	echo 'Error: failed to grab version of "svnadmin".'
	exit 1
fi

# Fetch a matching version from the Apache servers and unpack it
#
curl 'http://archive.apache.org/dist/subversion/subversion-'$svnadmin_version'.tar.bz2' > 'subversion-'$svnadmin_version'.tar.bz2'
bunzip2 'subversion-'$svnadmin_version'.tar.bz2'
tar -xvf 'subversion-'$svnadmin_version'.tar'

( if cd "subversion-$svnadmin_version" ; then
	
	# Build the two Apache modules
	#
	./configure
	make mod_dav_svn
	make mod_authz_svn
	
	# Fix up the two Apache modules
	#
	# Info: The resulting libraries contain references to /usr/local/lib and expect other dynlibs of subversion
	#       to be located there. Since we have those libs already inside Xcode, we update the internal links
	#       to those versions (else it will fail when loaded via httpd.) Alternatively the second set of dynlibs could
	#       be installed to /usr/local/lib, but that's a pointless waste of disk space, IMHO.
	#
	
	liblist=`otool -L subversion/mod_dav_svn/.libs/mod_dav_svn.so | sed -n 's/^'$'\t''\/usr\/local\/lib\/libsvn_\(.*\).dylib .*$/\1/p'`
	for lib in $liblist; do
		echo 'Fixing path of "libsvn_'$lib'" in mod_dav_svn.so…'
		install_name_tool -change '/usr/local/lib/libsvn_'"$lib"'.dylib' '/Applications/Xcode.app/Contents/Developer/usr/lib/libsvn_'"$lib"'.dylib' 'subversion/mod_dav_svn/.libs/mod_dav_svn.so'
	done
	# echo used lib list for verification
	otool -L 'subversion/mod_dav_svn/.libs/mod_dav_svn.so'
	
	
	liblist=`otool -L subversion/mod_authz_svn/.libs/mod_authz_svn.so | sed -n 's/^'$'\t''\/usr\/local\/lib\/libsvn_\(.*\).dylib .*$/\1/p'`
	for lib in $liblist; do
		echo 'Fixing path of "libsvn_'$lib'" in mod_authz_svn.so…'
		install_name_tool -change '/usr/local/lib/libsvn_'"$lib"'.dylib' '/Applications/Xcode.app/Contents/Developer/usr/lib/libsvn_'"$lib"'.dylib' 'subversion/mod_authz_svn/.libs/mod_authz_svn.so'
	done
	# echo used lib list for verification
	otool -L 'subversion/mod_authz_svn/.libs/mod_authz_svn.so'
	
	#
	# TODO: Maybe it would be smarter and go quicker to just build the two libs with the proper paths? :-P
	#	
else
	echo 'Error: Could not locate Apache Subversion source code.'
	exit 1
fi )

#  Clean up
#
mv "subversion-$svnadmin_version/subversion/mod_dav_svn/.libs/mod_dav_svn.so" './mod_dav_svn.so'
mv "subversion-$svnadmin_version/subversion/mod_authz_svn/.libs/mod_authz_svn.so" './mod_auth_svn.so'

rm -vrf "subversion-$svnadmin_version"
rm -vf "subversion-$svnadmin_version.tar"

printf '\n\nAll done!'

exit 0