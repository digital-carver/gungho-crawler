
package SimpleCrawler::Handler;
use strict;
use warnings;
use base qw(Gungho::Handler);
use HTML::LinkExtor;
use HTML::ResolveLink;
use DBI;

sub handle_response {
    my ( $self, $c, $request, $response ) = @_;

    return unless $response->is_success;
    return unless $response->content_type eq 'text/html';
    return if $request->uri =~ /robots\.txt$/;

    my $dbh = DBI->connect( 'dbi:SQLite:dbname=data/crawler.db',
        undef, undef, { RaiseError => 1, AutoCommit => 1 } );

    my $sth;
    $sth = $dbh->prepare_cached("UPDATE urls SET fetched_on = ?");
    eval { $sth->execute( time() ); };
    if ($@) {
        print $@, "\n";
    }

    my @links;
    my $code = sub {
        my ( $tag, %attrs ) = @_;
        return unless $tag eq 'a';

        push @links, $attrs{href};
    };

    my $resolver = HTML::ResolveLink->new( base => $request->uri );
    my $p = HTML::LinkExtor->new($code);
    $p->parse( $resolver->resolve( $response->content ) );
    $p->eof;

    foreach my $link (@links) {
        next if $link !~ /^https?\b/;
        eval {
            my $sth = $dbh->prepare("INSERT INTO urls (url) VALUES (?)");
            $sth->execute($link);
            $sth->finish;
        };
        if ($@) {
            print $@, "\n";
        }
    }
}

1;
