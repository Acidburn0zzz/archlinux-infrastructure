#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Data::Dumper;

umask 077;

# TODO put these into credentials.ini and use Config::Simple to read it
my $user = '{{ archweb_db_dbscripts_user }}';
my $pass = '{{ vault_archweb_db_dbscripts_password }}';
my $db = 'DBI:Pg:dbname={{ archweb_db }};host={{ archweb_db_host }}{% if postgres_ssl is defined and postgres_ssl == 'on' %};sslmode=require{% endif %}';

my $scriptdir="/etc/rsyncd-conf-genscripts";
my $infile="$scriptdir/rsyncd.conf.proto";
my $outfile="/etc/rsyncd.conf";
my $secrets_file = "/etc/rsyncd.secrets";

my $query = 'SELECT mrs.ip FROM mirrors_mirrorrsync mrs LEFT JOIN mirrors_mirror m ON mrs.mirror_id = m.id WHERE tier = 1 ORDER BY ip';

sub burp {
	my ($file_name, @lines) = @_;
	open (my $fh, ">", $file_name) || die sprintf(gettext("can't create '%s': %s"), $file_name, $!);
	print $fh @lines;
	close $fh;
}

my $dbh = DBI->connect($db, $user, $pass);
my $sth = $dbh->prepare($query);

$sth->execute;

$sth->rows > 0 or die "Failed to fetch IPs";

my @whitelist_ips;
while (my @ipaddr = $sth->fetchrow_array) {
	push @whitelist_ips, $ipaddr[0]
}


open (my $fh, "<", $infile) or die "Failed to open '$infile': $!";
my @data = <$fh>;
close $fh;

my $tier1_whitelist = join " ", @whitelist_ips;
for (@data) {
	s|\@\@ALLOWHOSTS_TIER1@@|$tier1_whitelist|;
}

burp($outfile, @data);

my @credentials = @{$dbh->selectall_arrayref("SELECT rsync_user, rsync_password FROM mirrors_mirror where tier = 1 and rsync_user != ''", {Slice=>{}})};
my $secrets_data = "";
for my $elem (@credentials) {
	$secrets_data .= sprintf "%s:%s\n", @{$elem}{qw(rsync_user rsync_password)};
}

burp($secrets_file, $secrets_data);

$dbh->disconnect;
