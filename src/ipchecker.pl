#!/usr/bin/perl
# 
# Copyright © 2009-2010 Nick Peelman
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# IPChecker.pl
# Writter by Nick Peelman
# November 12, 2009
#
# Changelog:
# v0.1 - 2009/11/12 - Creation!
#
# v0.2 - 2010/03/15 - Updated Logging, added LogLevel variable, updating package

$configfile		= "/Library/Preferences/us.peelman.ipchecker.launchd";
$cachedIPfile	= "/var/tmp/ipchecker.cache";
$cachedIP		= "";
$curl 			= "/usr/bin/curl";
$curlflags		= "-f -s -k";
$checkIPURL 	= "http://peelman.us/checkip.php";
$loglevel		= 0;

# Load Config File
if ( (! -e $configfile ) || (! -r $configfile ) ) {
	#print "IPChecker - No Config File Found!\n";
	`logger IPChecker Error - No Config File Found!`;
	exit 1;
}

open CONFIG, "<", $configfile or die "IPChecker - Error Reading Config File - $!";
if (! CONFIG){
	#print "IPChecker - Error Reading Config File!\n";
	`logger IPChecker Error - Problem Reading Config File`;
}

while (<CONFIG>) {
    chomp;                  # no newline
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
 	$$var = $value;
}

# Check Imported Config
if ( (!$username) || (!$password) || (!$hostname)  ){
	#print "IPChecker - Config File Error!\n";
	`logger IPChecker Error - Config File must have at least a Username, Password, and Hostname set!`;
	exit 1;	
}

# Check if CURL is present
if ( (! -e $curl ) || (! -x $curl ) ) {
	#print "IPChecker - curl Not Found!\n";
	`logger IPChecker Error - curl Not Found!`;
	exit 1;
}

# Set Up Command
my $command = "$curl $curlflags --basic --user $username:$password 'https://dynamic.zoneedit.com/auth/dynamic.html?host=$hostname'";

# Check for a cached IP
if ( (! -e $cachedIPfile ) ) {
	#print "IPChecker - No IP Cached, Updating IP!\n";
	`logger IPChecker - No IP Cached, Updating IP!`;
	`$curl $curlflags $checkIPURL > $cachedIPfile`;
	`$command`;
	exit 0;
} else {
	$cachedIP = `cat $cachedIPfile`;
}

# Check Cached IP Against Current IP
if ( $cachedIP != `$curl $curlflags $checkIPURL` ) {
	#print "IPChecker - IP Changed!  Updating IP!\n";
	`logger IPChecker - IP Changed! Updating IP!`;
	`$curl $curlflags $checkIPURL > $cachedIPfile`;
	`$command`;
	exit 0;
} else {
	if ($loglevel > 0)
		`logger IPChecker - No Change`;
}

exit 0;