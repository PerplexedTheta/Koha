#!/usr/bin/perl

# Parts copyright 2014 ByWater Solutions
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use Getopt::Long qw( GetOptions );
use Pod::Usage   qw( pod2usage );

use Koha::Script;
use Koha::Patrons::Import;
use C4::Log qw( cronlogaction );
my $Import = Koha::Patrons::Import->new();

my $csv_file;
my $matchpoint;
my $overwrite_cardnumber;
my $overwrite_passwords;
my $welcome_new = 0;
my %defaults;
my $ext_preserve = 0;
my $confirm;
my $verbose = 0;
my $help;
my @preserve_fields;
my $update_dateexpiry;
my $update_dateexpiry_from_today;
my $update_dateexpiry_from_existing;

my $command_line_options = join( " ", @ARGV );

GetOptions(
    'c|confirm'                      => \$confirm,
    'f|file=s'                       => \$csv_file,
    'm|matchpoint=s'                 => \$matchpoint,
    'd|default=s'                    => \%defaults,
    'o|overwrite'                    => \$overwrite_cardnumber,
    'op|overwrite_passwords'         => \$overwrite_passwords,
    'ue|update-expiration'           => \$update_dateexpiry,
    'et|expiration-from-today'       => \$update_dateexpiry_from_today,
    'ee|expiration-from-existing'    => \$update_dateexpiry_from_existing,
    'en|email-new'                   => \$welcome_new,
    'p|preserve-extended-attributes' => \$ext_preserve,
    'pf|preserve-field=s'            => \@preserve_fields,
    'v|verbose+'                     => \$verbose,
    'h|help|?'                       => \$help,
) or pod2usage(2);

pod2usage(1)                                       if $help;
pod2usage(q|--ee and --et are mutually exclusive|) if $update_dateexpiry_from_today && $update_dateexpiry_from_existing;
pod2usage(q|--file is required|)       unless $csv_file;
pod2usage(q|--matchpoint is required|) unless $matchpoint;

if ($confirm) {
    cronlogaction( { action => 'Run', info => $command_line_options } );
} else {
    warn "Running in dry-run mode, provide --confirm to apply the changes\n";
}

my $handle;
open( $handle, "<", $csv_file ) or die $!;

my $return = $Import->import_patrons(
    {
        file                            => $handle,
        defaults                        => \%defaults,
        matchpoint                      => $matchpoint,
        overwrite_cardnumber            => $overwrite_cardnumber,
        overwrite_passwords             => $overwrite_passwords,
        preserve_extended_attributes    => $ext_preserve,
        preserve_fields                 => \@preserve_fields,
        update_dateexpiry               => $update_dateexpiry,
        update_dateexpiry_from_today    => $update_dateexpiry_from_today,
        update_dateexpiry_from_existing => $update_dateexpiry_from_existing,
        send_welcome                    => $welcome_new,
        dry_run                         => !$confirm,
    }
);

my $feedback    = $return->{feedback};
my $errors      = $return->{errors};
my $imported    = $return->{imported};
my $overwritten = $return->{overwritten};
my $alreadyindb = $return->{already_in_db};
my $invalid     = $return->{invalid};
my $total       = $imported + $alreadyindb + $invalid + $overwritten;

if ($verbose) {
    say q{};
    say "Import complete:";
    say "Imported:    $imported";
    say "Overwritten: $overwritten";
    say "Skipped:     $alreadyindb";
    say "Invalid:     $invalid";
    say "Total:       $total";
    say q{};
}

if ( $verbose > 1 ) {
    say "Errors:";
    say Data::Dumper::Dumper($errors);
}

if ( $verbose > 2 ) {
    say "Feedback:";
    say Data::Dumper::Dumper($feedback);
}

my $info =
      "Import complete. "
    . "Imported: "
    . $imported
    . " Overwritten: "
    . $overwritten
    . " Skipped: "
    . $alreadyindb
    . " Invalid: "
    . $invalid
    . " Total: "
    . $total;

if ($confirm) {
    cronlogaction( { action => 'End', info => $info } );
}

=head1 NAME

import_patrons.pl - CLI script to import patrons data into Koha

=head1 SYNOPSIS

import_patrons.pl --file /path/to/patrons.csv --matchpoint cardnumber --confirm [--default branchcode=MPL] [--overwrite] [--preserve-field <column>] [--preserve-extended-attributes] [--update-expiration] [--expiration-from-today] [--verbose]

=head1 OPTIONS

=over 8

=item B<-h|--help>

Prints a brief help message and exits

=item B<-c|--confirm>

Confirms you really want to import these patrons, otherwise prints this help

=item B<-f|--file>

Path to the CSV file of patrons to import

=item B<-m|--matchpoint>

Field on which to match incoming patrons to existing patrons

=item B<-d|--default>

Set defaults to patron fields, repeatable e.g. --default branchcode=MPL --default categorycode=PT

=item B<-k|--preserve-field>

Prevent specified patron fields for existing patrons from being overwritten

=item B<-o|--overwrite>

Overwrite existing patrons with new data if a match is found

=item B<-p|--preserve-extended-attributes>

Retain extended patron attributes for existing patrons being overwritten

=item B<-en|--email-new>

Send the WELCOME notice email to new users

=item B<-ue|--update-expiration>

If a matching patron is found, extend the expiration date of their account using the patron's enrollment date as the base

=item B<-et|--expiration-from-today>

If a matching patron is found, extend the expiration date of their account using today's date as the base
Cannot by used in conjunction with --expiration-from-existing

=item B<-ee|--expiration-from-existing>

If a matching patron is found, extend the expiration date of their account using the patron's current expiration date as the base
Cannot by used in conjunction with --expiration-from-today

=item B<-v|--verbose>

Be verbose

Multiple -v options increase the verbosity

2 repetitions or above will report lines in error

3 repetitions or above will report feedback

=back

=cut
