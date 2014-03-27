#!/usr/bin/perl
# Glyn Astill - 02/03/2014
# Script to automate cs2cs transform from esatings/northings to latitudes/longitudes
# for PAF files from Royal Mail

#use diagnostics;
use strict;
use warnings;
use Getopt::Long qw/GetOptions/;
use Geo::Proj4;

use constant false => 0;
use constant true  => 1;

my $error;
my $usage = '-i <codepoint csv file input> -o <latlong csv file output>';
my $infile;
my $outfile;
my @latlong;
my $linecount;
my @infiles;
my @fields_fixed;
my $start_run = time();
my $end_run;
my $run_time;
my $pipe_cs2cs = true;
my $proj_ng;
my $proj_ig;

# Handle command line options
Getopt::Long::Configure('no_ignore_case');
use vars qw{%opt};
die $usage unless GetOptions(\%opt, 'infile|i=s', 'outfile|o=s', ) and keys %opt and ! @ARGV;

if (!defined($opt{infile})) {
	print("Please specify an input file.\n");
	die $usage;
}
else {
	$infile = $opt{infile};
}
if (!defined($opt{outfile})) {
	print("Please specify an output file.\n");
	die $usage;
}
else {
	$outfile = $opt{outfile};
}

if (!$pipe_cs2cs) {
	# I'm not positive that the below is setting a the Bursa Wolf or another parameter correctly, hence loss in accuracy.
	# it's possible to set the parameters individually i.e. "Geo::Proj4->new(proj => "tmerc", ellps => "airy", lat_0 => -49)" which may solve
	$proj_ng = Geo::Proj4->new("-f '%.7f' +proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +towgs84=446.448,-125.157,542.060,0.1502,0.2470,0.8421,-20.4894 +units=m +no_defs +to +proj=latlong +ellps=WGS84 +towgs84=0,0,0 +nodefs")
		or die "parameter error: ".Geo::Proj4->error. "\n";
	$proj_ig = Geo::Proj4->new("-f '%.7f' +proj=tmerc +lat_0=53.5 +lon_0=-8 +k=1.000035 +x_0=200000 +y_0=250000 +ellps=airy +towgs84=482.530,-130.596,564.557,-1.042,-0.214,-0.631,8.15 +units=m +no_defs +to +proj=latlong +ellps=WGS84 +towgs84=0,0,0 +nodefs")
		or die "parameter error: ".Geo::Proj4->error. "\n";
}

# Read the codepoint file with eastings and northings, convert and output to outfile
# Open our output file which will contain the eastings/northings and longitudes/latitudes
if (open(OUTFILE, ">", $outfile)) {
	
	# get a list of our files 
	$infile =~ s/ /\\ /g;
	@infiles = glob("$infile");

	foreach my $currfile (@infiles) {
		# read in the file
		$linecount = 0;	
		print ("Processing $currfile ..");
		unless (open(INFILE, "<", $currfile)) {
			print("ERROR: Could not open file:" . $! . ".\n");
		}
		while (<INFILE>) {
			@fields_fixed = unpack('a4 a3 a6 a5 a5 a9 a9 a9 a9 a9 a9 a1 a1', $_);

			eval {
				# Deal with 6 digit northings
				for ($fields_fixed[4]) {
					s/[PO]/12/;
					s/[UT]/11/;
					s/[ZY]/10/;
				}
				if ($fields_fixed[4] =~ m/\s/) {
					$fields_fixed[4] = sprintf("%-6s", $fields_fixed[4]) . " ";
					$fields_fixed[3] .= ' ';
				}
				else {
					$fields_fixed[4] = sprintf("%06d", $fields_fixed[4]) . "0";
					$fields_fixed[3] .= '0';
				}
				
				for (my $field = 0; $field <= 12; $field++) {
					print OUTFILE ($fields_fixed[$field]);
				}
				
				if ($fields_fixed[4] !~ m/\s/) {
					# Irish Grid
					if ($fields_fixed[0] =~ m/^BT/i) {
						if ($pipe_cs2cs) {
							open(CS2CS,"echo $fields_fixed[3] $fields_fixed[4] | cs2cs -f '%.7f' +proj=tmerc +lat_0=53.5 +lon_0=-8 +k=1.000035 +x_0=200000 +y_0=250000 +ellps=airy +towgs84=482.530,-130.596,564.557,-1.042,-0.214,-0.631,8.15 +units=m +no_defs +to +proj=latlong +ellps=WGS84 +towgs84=0,0,0 +nodefs |");
						}
						else {
							@latlong = $proj_ig->inverse($fields_fixed[3], $fields_fixed[4]);
						}						
					}
					# National Grid
					else {
						if ($pipe_cs2cs) {
							open(CS2CS,"echo $fields_fixed[3] $fields_fixed[4] | cs2cs -f '%.7f' +proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +towgs84=446.448,-125.157,542.060,0.1502,0.2470,0.8421,-20.4894 +units=m +no_defs +to +proj=latlong +ellps=WGS84 +towgs84=0,0,0 +nodefs |");
						}
						else {
							@latlong = $proj_ng->inverse($fields_fixed[3], $fields_fixed[4]);
						}
					}

					if ($pipe_cs2cs) {
						@latlong =  split(' ', <CS2CS>);
						close CS2CS;
						print OUTFILE (sprintf("%010f", $latlong[1]) . sprintf("%010f", $latlong[0]));
					}
					else {					
						print OUTFILE (sprintf("%010f", $latlong[0]) . sprintf("%010f", $latlong[1]));
					}
					
				}
				else {
					print OUTFILE "                    ";
				}
				
				print OUTFILE ("\n");
				$linecount++;
				if (($linecount%10000) == 0) {
					print ("..$linecount");
				}
			};
			if ($@) {
				print("ERROR: Could not run command:" . $! . " Line = " . $_ . "\n");
				print("$fields_fixed[3] $fields_fixed[4]");
			}
			
		}
		close (INFILE);
		print ("..OK\n");
	}

	close (OUTFILE);
}
else {
	print("ERROR: Could not open file:" . $! . ".\n");
}

$end_run = time();
$run_time = (($end_run-$start_run)/60);

print "Conversion took $run_time minutes\n";
if ($pipe_cs2cs) {
	print "To run quicker use Geo:proj4 (appears to be less accurate - a bug in my usage?) or stream the data directly to cs2cs in one go rather than constantly calling and opening the commands output\n";
}

exit(0);