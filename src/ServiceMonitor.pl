# $Header: /var/lib/cvsd/var/lib/cvsd/ServiceMonitor/src/ServiceMonitor.pl,v 1.2 2012-10-30 17:02:07 timb Exp $
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# (c) Tim Brown, 2004
# <mailto:timb@nth-dimension.org.uk>
# <http://www.nth-dimension.org.uk/> / <http://www.machine.org.uk/>

use strict;
use Win32::Service;
use Net::SMTP;
use Win32;

my @servicenames;
my $servicestatusline;
my $servicename;
my $servicestatus;
my %servicestatus;
my $servicestatusfile;
my $notifyadminflag;
my %servicestatuscurrent;
my $serviceupstate;
my $servicestate;
my $smtphandle;
my $mailrelay;
my @mailrelays;
my $emailsentflag;
my $adminemailaddress;
my @adminemailaddresses;

# set the services to watch
@servicenames = (
);
# set the service status file, \\ for \ in Windows filenames
$servicestatusfile = ""
# set the mail relays, 2 for redundancy
@mailrelays = (
);
# set the admin email addresses
@adminemailaddresses = (
);

foreach $servicename (@servicenames) {
	$servicestatus{$servicename} = "1";
}
if ( -e $servicestatusfile ) {
	open(SERVICESTATUSFILEHANDLE, $servicestatusfile);
	while (<SERVICESTATUSFILEHANDLE>) {
		$servicestatusline = $;
		$servicestatusline =~ /([A-z ]*) ([01]) ([=>]) ([01])/;
		$servicename = $1;
		$servicestatus = $4;
		$servicestatus{$servicename} = $servicestatus;
	}
	close(SERVICESTATUSFILEHANDLE);
}
$serviceupstate = "4";
$notifyadminflag = "0";
foreach $servicename (@servicenames) {
	Win32::Service::GetStatus("", $servicename, \%servicestatuscurrent);
	if ($servicestatuscurrent{"CurrentState"} != $serviceupstate) {
		$servicestatus = "0"; 	
	} else {
		$servicestatus = "1";
	}
	if ($servicestatus != $servicestatus{$servicename}) {
		$servicestate = ">";
	} else {
		$servicestate = "=";
	}
	$servicestatus{$servicename} = $servicestatus{$servicename} . " " . $servicestate . " " . $servicestatus;
	if ($notifyflag == "0" && $servicestate == ">" && $servicestatus == "0") {
		$notifyflag = "1";
	}
}
open(SERVICESTATUSFILEHANDLE, ">c:\\SystemMonitor\\ServiceStatus.txt");
foreach $servicename (@servicenames) {
	print SERVICESTATUSFILEHANDLE $servicename . " " . $servicestatus{$servicename} . "\n";
}
close(SERVICESTATUSFILEHANDLE);
if ($notifyflag == "1") {
	$emailsentflag = "0";
	foreach $mailrelay (@mailrelays) {
		if ($emailsentflag == "0") {
			$smtphandle = Net::SMTP->new($mailrelay);
			if ($smtphandle) {
				foreach $adminemailaddress (@adminemailaddresses) {
					$smtphandle->mail($adminemailaddress);
					$smtphandle->to($adminemailaddress);
					$smtphandle->data();
					$smtphandle->datasend("To: " . $adminemailaddress .  " . \n");
					$smtphandle->datasend("Subject: SYSTEM ALERT (" . Win32::NodeName() . ")\n");
					$smtphandle->datasend("\n");
					foreach $servicename (@servicenames) {
						$smtphandle->datasend($servicename . " " . $servicestatus{$servicename} . "\n");
					}
					$smtphandle->dataend();
				}
				$smtphandle->quit();
				$emailflag = "1";
			}
		}
	}
}
