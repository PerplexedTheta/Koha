#!/usr/bin/perl
#
# This Koha test module is a stub!
# Add more tests here!!!

use Modern::Perl;

use Test::More tests => 6;
use List::MoreUtils qw(any none);
use MARC::Record;
use C4::Biblio qw( GetMarcFromKohaField AddBiblio );
use C4::XISBN  qw( get_xisbns );
use C4::Context;
use C4::Search;
use Koha::Database;
use t::lib::Mocks;
use Test::MockModule;

BEGIN {
    use_ok( 'C4::XISBN', qw( get_xisbns ) );
}

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $engine        = C4::Context->preference("SearchEngine") // 'Zebra';
my $search_module = Test::MockModule->new("Koha::SearchEngine::${engine}::Search");

$search_module->mock( 'simple_search_compat', \&Mock_simple_search_compat );

my $context = C4::Context->new;

my ( $biblionumber_tag, $biblionumber_subfield ) = GetMarcFromKohaField('biblio.biblionumber');
my ( $isbn_tag,         $isbn_subfield )         = GetMarcFromKohaField('biblioitems.isbn');

# Harry Potter and the Sorcerer's Stone, 1st American ed. 1997
my $isbn1 = '0590353403';

# ThingISBN match : Silent Wing, First Edition 1998
my $isbn2 = '0684843897';

# XISBN match : Harry Potter and the Sorcerer's Stone,
# 1. Scholastic mass market paperback printing1.
my $isbn3 = '043936213X';

# Finn Family Moomintroll, won't match to other isbns
my $isbn4 = '014030150X';

my $biblionumber1 = _add_biblio_with_isbn($isbn1);
my $biblionumber2 = _add_biblio_with_isbn($isbn2);
my $biblionumber3 = _add_biblio_with_isbn($isbn3);
my $biblionumber4 = _add_biblio_with_isbn($isbn4);

my $trial = C4::XISBN::_get_biblio_from_xisbn($isbn1);
is(
    $trial->{biblionumber},
    $biblionumber1, "Gets biblionumber like the previous test."
);

## Test ThingISBN
t::lib::Mocks::mock_preference( 'ThingISBN', 1 );

my $results_thingisbn;
eval { $results_thingisbn = C4::XISBN::get_xisbns( $isbn1, $biblionumber4 ); };
SKIP: {
    skip "Problem retrieving ThingISBN", 2
        unless $@ eq '';
    ok(
        ( any { $_->{'biblionumber'} eq $biblionumber1 } @$results_thingisbn ),
        "Gets correct biblionumber from a book with a similar isbn using ThingISBN."
    );
    ok(
        ( any { $_->{'biblionumber'} eq $biblionumber3 } @$results_thingisbn ),
        "Gets correct biblionumber from a book with a similar isbn using ThingISBN."
    );
}

eval { $results_thingisbn = C4::XISBN::get_xisbns( $isbn1, $biblionumber1 ); };
SKIP: {
    skip "Problem retrieving ThingISBN", 1
        unless $@ eq '';
    is(
        $results_thingisbn->[0]->{biblionumber},
        $biblionumber3,
        "Gets correct biblionumber from a different book with a similar isbn using ThingISBN."
    );
}

eval { $results_thingisbn = C4::XISBN::get_xisbns( $isbn1, $biblionumber3 ); };
SKIP: {
    skip "Problem retrieving ThingISBN", 1
        unless $@ eq '';
    ok(
        ( none { $_->{'biblionumber'} eq $biblionumber3 } @$results_thingisbn ),
        "Doesn't get biblionumber if the biblionumber matches the one passed to the sub."
    );
}

# Util subs

# Add new biblio with isbn and return biblionumber
sub _add_biblio_with_isbn {
    my $isbn = shift;

    my $marc_record = MARC::Record->new;
    my $field       = MARC::Field->new( $isbn_tag, '', '', $isbn_subfield => $isbn );
    $marc_record->append_fields($field);
    my ( $biblionumber, $biblioitemnumber ) = AddBiblio( $marc_record, '' );
    return $biblionumber;
}

# Mocked subs

# Koha::SearchEngine::${SearchEngine}::Search::simple_search_compat
sub Mock_simple_search_compat {
    my $self  = shift;
    my $query = shift;
    my @results;

    $query =~ s/-//g;
    my $ret_biblionumber;
    if ( $query eq "nb=$isbn1" ) {
        $ret_biblionumber = $biblionumber1;
    } elsif ( $query eq "nb=$isbn2" ) {
        $ret_biblionumber = $biblionumber2;
    } elsif ( $query eq "nb=$isbn3" ) {
        $ret_biblionumber = $biblionumber3;
    }

    my $record = MARC::Record->new;
    $record->leader('     ngm a22     7a 4500');
    my $biblionumber_field;
    if ( $biblionumber_tag < 10 ) {
        $biblionumber_field = MARC::Field->new( $biblionumber_tag, $ret_biblionumber );
    } else {
        $biblionumber_field = MARC::Field->new(
            $biblionumber_tag, '', '',
            $biblionumber_subfield => $ret_biblionumber
        );
    }
    $record->append_fields($biblionumber_field);

    push @results, $record->as_xml();

    return ( undef, \@results, 1 );
}
