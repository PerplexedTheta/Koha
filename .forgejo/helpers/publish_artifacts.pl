#!/usr/bin/env perl

# Copyright (C) 2026 Open Fifth Ltd
#
# This file is part of Koha
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
# along with Koha; if not, see <https://www.gnu.org/licenses>.

# Auto-install required modules if missing
BEGIN {
    my @required = qw(Modern::Perl IPC::Cmd);
    my @missing;

    for my $module (@required) {
        eval "require $module; 1" or push @missing, $module;
    }

    if (@missing) {
        print "Installing missing Perl modules: " . join( ', ', @missing ) . "\n";
        system( 'cpan', '-i', @missing ) == 0
            or die "Failed to install modules: $!\n";
        exec( $^X, $0, @ARGV );    # Re-exec script with new modules
    }
}

use Modern::Perl;

use File::Temp qw(tempdir);
use Getopt::Long;
use Cwd      qw(abs_path getcwd);
use IPC::Cmd qw(run run_forked);

my $verbose = 0;
my $help    = 0;

GetOptions(
    'help|h'    => \$help,
    'verbose|v' => \$verbose,
);

if ($help) {
    print_help();
    exit 0;
}

die('No package owner and/or release specified. Ensure FORGEJO_OWNER and KOHA_RELEASE are set.')
    unless ( $ENV{FORGEJO_OWNER} && $ENV{KOHA_RELEASE} );

my $token     = $ENV{KOHA_FORGEJO_TOKEN} || $ENV{FORGEJO_TOKEN};
my $artifacts = 'koha-deb-pkgs';

# Find all the deb files
opendir my $deb_dir, "$ENV{FORGEJO_WORKSPACE}/$artifacts"
    or die "Cannot opendir on $ENV{FORGEJO_WORKSPACE}/$artifacts: $!";
my @debs = grep /.deb$/, readdir $deb_dir or die "Cannot readdir on $ENV{FORGEJO_WORKSPACE}/$artifacts: $!";

# push each debfile to a repo
for my $deb (@debs) {
    run_cmd(
        qq{
            curl -o/dev/null -s -w "\%{http_code}\\n" \\
                 --user git:$token \\
                 --upload-file $ENV{FORGEJO_WORKSPACE}/$artifacts/$deb \\
                 https://forgejo.ishukone.net/api/packages/$ENV{FORGEJO_OWNER}/debian/pool/koha/$ENV{KOHA_RELEASE}/upload
        },
        { exit_on_error => 1 }
    );
}

sub run_cmd {
    my ( $cmd, $params ) = @_;
    my $exit_on_error = $params->{exit_on_error} // 0;
    my $real_time     = $params->{real_time}     // $verbose;
    my $env           = $params->{env}           // {};

    my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) = IPC::Cmd::run(
        command => $cmd,
        verbose => $real_time,
        timeout => 120,          # cloning scripts should be fast
        %$env ? ( env => $env ) : (),
    );

    if ( !$success && $exit_on_error ) {

        # Print tail of captured output for context
        if ( $stderr_buf && @$stderr_buf ) {
            my $tail  = join( '', @$stderr_buf );
            my @lines = split /\n/, $tail;
            @lines = @lines[ -20 .. -1 ] if @lines > 20;
            print STDERR "--- Last stderr output ---\n" . join( "\n", @lines ) . "\n---\n";
        }
        die "Command failed: $error_message\n";
    }

    return $success;
}

sub print_help {
    print <<'EOF';
EOF
}
