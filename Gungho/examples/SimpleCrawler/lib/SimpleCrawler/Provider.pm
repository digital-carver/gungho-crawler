package SimpleCrawler::Provider;
use strict;
use warnings;
use base qw(Gungho::Provider::Simple);
use DBI;

__PACKAGE__->mk_accessors($_) for qw(dbh connect_info);

# XXX - do DBI setup in setup(), and use Simple's

sub new {
    my $class = shift;
    return $class->next::method(
        connect_info => [
            'dbi:SQLite:dbname=data/crawler.db',
            undef, undef, { RaiseError => 1, AutoCommit => 1 }
        ]
    );
}

sub setup {
    my ( $self, $c ) = @_;
    my $dbh = DBI->connect( @{ $self->connect_info } )
      or die "Could not connect to database";

    my $sth  = $dbh->prepare("SELECT url FROM urls");
    my $rows = $sth->execute();

    my $url;
    $sth->bind_columns( \$url );
    while ( $sth->fetchrow_arrayref ) {
        my $r = Gungho::Request->new( GET => $url );
        $self->add_request($r);
    }
}

1;