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

# Determine branch
my $branch = $ENV{KDD_BRANCH} || $ENV{KDD_IMAGE} || $ENV{KOHA_RELEASE} || 'main';

# Create temporary directory for kdd-helper-script
my $tmp_dir = tempdir( 'kdd-helper-script-XXXXXX', TMPDIR => 1 );
if ($verbose) {
    print "Output directory: $tmp_dir\n";
}

# Clone down jenkins-helper-scripts
chdir($tmp_dir) or die "Cannot chdir to $tmp_dir: $!";
run_cmd(
    qq{wget -O $tmp_dir/build.pl https://mirror.openfifth.net/~jenkins/build/$branch/build.pl},
    { exit_on_error => 1 }
);

# Export environment
run_cmd(
    qq{
        export KDD_HELPER_SCRIPTS="$tmp_dir"
        echo KDD_HELPER_SCRIPTS="$tmp_dir" >> $ENV{FORGEJO_ENV}
    },
    { exit_on_error => 1 }
);
run_cmd(
    qq{
        export KDD_BRANCH="$branch"
        echo KDD_BRANCH="$branch" >> $ENV{FORGEJO_ENV}
    },
    { exit_on_error => 1 }
);

# Revert to original dir
chdir( $ENV{FORGEJO_WORKSPACE} ) or die "Cannot chdir to $ENV{FORGEJO_WORKSPACE}: $!";

# Create temporary directory for debs-out
my $debs_dir = tempdir( 'debs-out-XXXXXX', TMPDIR => 1 );
if ($verbose) {
    print "Debs directory: $debs_dir\n";
}

# Export environment
run_cmd(
    qq{
        export DEBS_OUT="$debs_dir"
        echo DEBS_OUT="$debs_dir" >> $ENV{FORGEJO_ENV}
    },
    { exit_on_error => 1 }
);

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
