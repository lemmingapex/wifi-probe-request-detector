#!/usr/bin/perl

use strict;
use Getopt::Long;

$SIG{USR1}	= \&writeOutput;
$SIG{INT}	= \&cleanKill;
$SIG{KILL}	= \&cleanKill;
$SIG{TERM}	= \&cleanKill;

my $pid;
my %detectedMACs;

my $interface = "wlan0";
my $outfile = "probe-request-detector-output.txt";
my $options = GetOptions(
	"interface=s"		=> \$interface,
	"outfile=s"		=> \$outfile,
);

($ENV{USER} ne "root") && die "$0 must be run by root!\n";
(!$interface) && die "No wireless interface specified!\n";

# Configure wireless interface
(system("ifconfig $interface down")) && die "Can not initialize interface $interface!\n";
# set mode to monitor instead of managed
(system("iwconfig $interface mode monitor")) && die "Can not set interface $interface in monitoring mode!\n";
(system("ifconfig $interface up")) && die "Can not initialize interface $interface!\n";

# Create the child process
(!defined($pid = fork)) && die "Can not fork child process!\n";

if ($pid) {
	# Parent process
	# run tshark
	open(TSHARK, "tshark -i $interface -l subtype probereq 2>/dev/null |") || die "Can not spawn tshark!\n";
	while (<TSHARK>) {
		chomp;
		my $line = $_;
		chomp($line = $_);
		if($line = m/\d+\.\d+ ([a-zA-Z0-9:_]+).+SSID=(.+) (.+) dBm/) {
			my $macAddress = $1;
			my $ssid = $2;
			my $RSSI = $3;
			my $key = $macAddress.$ssid;
			if($ssid ne "Broadcast") { # Ignore ssid=broadcast
				if (! $detectedMACs{$key}) {
					my @networkObject = ($macAddress, $ssid, time(), 1, $RSSI);
					$detectedMACs{$key} = [ @networkObject ];
				} else {
					$detectedMACs{$key}[1] = $ssid;
					$detectedMACs{$key}[2] = time();
					$detectedMACs{$key}[3] = ($detectedMACs{$key}[3] + 1);
					$detectedMACs{$key}[4] = (($detectedMACs{$key}[4]*($detectedMACs{$key}[3] - 1)) + $RSSI)/($detectedMACs{$key}[3]);
				}
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($detectedMACs{$key}[2]);
				my $lastSeen = sprintf("%04d/%02d/%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
				print STDOUT sprintf("%-20s %-30s %-20s %-12s %.2f\n", $detectedMACs{$key}[0], $detectedMACs{$key}[1], $lastSeen, $detectedMACs{$key}[3], $detectedMACs{$key}[4]);
			}
		}
	}
} else {
	# Child process
	# change channels/frequencies every 4 seconds
	while (1) {
		for (my $channel = 1; $channel <= 12; $channel++) {
			(system("iwconfig $interface channel $channel")) && die "Can not set interface channel.\n";
			sleep(4);
		}
	}

}

sub writeOutput {
	my $i;
	my $key;
	open(OUTFILE, ">$outfile") || die "Can not write to $outfile (Error: $?)";
	print OUTFILE "MAC Address          SSID                           Last Seen            Packet Count Average RSSI\n";
	print OUTFILE "-------------------- ------------------------------ -------------------- ------------ ------------\n";
	for $key ( keys %detectedMACs) {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($detectedMACs{$key}[2]);
		my $lastSeen = sprintf("%04d/%02d/%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
		print OUTFILE sprintf("%-20s %-30s %-20s %-12s %.2f\n", $detectedMACs{$key}[0], $detectedMACs{$key}[1], $lastSeen, $detectedMACs{$key}[3], $detectedMACs{$key}[4]);
	}
	close(OUTFILE);
	return;
}

sub cleanKill {
	if ($pid) {
		kill 1, $pid;
		writeOutput;
	}
	exit 0;
}
