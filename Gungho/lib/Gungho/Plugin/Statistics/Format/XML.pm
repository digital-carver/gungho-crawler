# $Id$

package Gungho::Plugin::Statistics::Format::XML;
use strict;
use warnings;
use base qw(Gungho::Base);
use XML::LibXML;

sub format
{
    my ($self, $storage, $output) = @_;

    $output ||= \*STDOUT;

    my $doc = XML::LibXML::Document->new("1.0", "UTF-8");
    my $root = $doc->createElement('GunghoStatstics');
    $doc->setDocumentElement( $root );

    my $parent = $root;
    foreach my $name qw(active_requests finished_requests) {
        my $tag = $name;
        $tag =~ s/(?:\b|_)(.)/uc $1/ge;
        my $el = $doc->createElement($tag);
        my $value = $storage->get($name);
        if (defined $value) {
            $el->appendText($value);
        }
        $parent->appendChild($el);
    }

    print $output $doc->toString();
}

1;
