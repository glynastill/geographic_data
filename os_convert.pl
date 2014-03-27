#!/usr/bin/perl

# Glyn Astill - 11/10/2012
# Script to automate cs2cs transform from esatings/northings to latitudes/longitudes

use strict;
use warnings;
use Text::CSV;
use Geo::Proj4;
use Getopt::Long qw/GetOptions/;

use constant false => 0;
use constant true  => 1;

my $csv = Text::CSV->new();
my $error;
my $usage = '-i <codepoint csv file input> -o <latlong csv file output>';
my $infile;
my $outfile;
my @latlong;
my @eastnorth;
my $linecount;
my @infiles;
my $start_run = time();
my $end_run;
my $run_time;
my $pipe_cs2cs = true;
my $proj_ng;

if (!$pipe_cs2cs) {
	# I'm not positive that the below is setting a the Bursa Wolf or another parameter correctly, hence loss in accuracy.
	# it's possible to set the parameters individually i.e. "Geo::Proj4->new(proj => "tmerc", ellps => "airy", lat_0 => -49)" which may solve
	$proj_ng = Geo::Proj4->new("-f '%.7f' +proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +towgs84=446.448,-125.157,542.060,0.1502,0.2470,0.8421,-20.4894 +units=m +no_defs +to +proj=latlong +ellps=WGS84 +towgs84=0,0,0 +nodefs")
}

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

# Read the codepoint file with eastings and northings, convert and output to outfile
# Open our output file which will contain the eastings/northings and longitudes/latitudes and write a headder
if (open(OUTCSV, ">", $outfile)) {
	print OUTCSV ("postcode,easting,northing,latitude,longitude,country_code,admin_county_code,admin_district_code,admin_ward_code\n");	

	# get a list of our files 
	@infiles = glob($infile);

	foreach my $currfile (@infiles) {
		# read in the file
		$linecount = 0;	
		print ("Processing $currfile ..");
		unless (open(INCSV, "<", $currfile)) {
			print("ERROR: Could not open file:" . $! . ".\n");
		}
		while (<INCSV>) {
			if ($csv->parse($_)) {
				@eastnorth=$csv->fields();

				eval {
					if ($pipe_cs2cs) {
						open(CS2CS,"echo $eastnorth[2] $eastnorth[3] | cs2cs -f '%.7f' +proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +towgs84=446.448,-125.157,542.060,0.1502,0.2470,0.8421,-20.4894 +units=m +no_defs +to +proj=latlong +ellps=WGS84 +towgs84=0,0,0 +nodefs |");
					}
					else {
						@latlong = $proj_ng->inverse($eastnorth[2], $eastnorth[3]);
					}
					
					if ($pipe_cs2cs) {
						@latlong =  split(' ', <CS2CS>);
						close CS2CS;
						print OUTCSV ("$eastnorth[0],$eastnorth[2],$eastnorth[3],$latlong[1],$latlong[0],$eastnorth[4],$eastnorth[7],$eastnorth[8],$eastnorth[9]\n");
					}
					else {					
						print OUTCSV ("$eastnorth[0],$eastnorth[2],$eastnorth[3],$latlong[0],$latlong[1],$eastnorth[4],$eastnorth[7],$eastnorth[8],$eastnorth[9]\n");
						
						
						
					}
				};
				if ($@) {
					print("ERROR: Could not run command:" . $! . " Line = " . $_ . "\n");
					print("$eastnorth[2] $eastnorth[3]");
				}
	
				$linecount++;
				if (($linecount%1000) == 0) {
					print ("..$linecount");
				}
			}
			else {
				$error = $csv->error_input;
				print("\tFailed to parse line: $error\n");	
			}	
		}
		close (INCSV);
		print ("..OK\n");
	}

	close (OUTCSV);
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
