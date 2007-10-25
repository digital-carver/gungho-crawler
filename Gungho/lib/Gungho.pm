# $Id$
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho;
use strict;
use warnings;
use 5.008;
use base qw(Class::C3::Componentised);
our $VERSION = '0.09000';

__PACKAGE__->load_components('Setup');

sub component_base_class { "Gungho::Component" }

1;

__END__

=head1 NAME

Gungho - Yet Another High Performance Web Crawler Framework

=head1 SYNOPSIS

  use Gungho;
  Gungho->run($config);

=head1 DESCRIPTION

What, another crawler? 

YES. Gungho is Yet Another Web Crawler Framework, aimed to be extensible and
fast. It is a culmination of lessons learned while building another
crawler named Xango -- Xango was *fast*, but it was horribly hard to debug or
to extend (Gungho even works right out of the box ;)

Therefore, Gungho's main aim is to make it as easy as possible to write
complex crawlers, while still keeping crawling *fast*. You can simply specify
the urls to fetch and some code to handle the responses -- we do the rest.

Gungho tries to build from clean structures, based upon principles from the
likes of Catalyst, DBIx::Class, and Plagger, so that you can easily extend 
it to your liking.

Features such as robot rules handling (robots.txt) and request throttling
can be removed/added on the fly, just by specifying the components that
you want to load. You can easily create additional functionality by writing
your own component.

Gungho is still very fast -- it uses event driven frameworks such as
POE, Danga::Socket, and IO::Async as the main engine to drive requests.
Choose the best engine for your needs: For example, if you plan on creating
a POE-based handler to process the response, you might choose the POE engine -
it will fit nicely into the request cycle. However, do note that the most
heavily excercised engine is POE. Danga::Socket and IO::Async works, but
haven't been tested too vigorously. Please send in requests and bug reports
if you encounter any problems.

WARNING: *ALL* APIs are still subject to change.

=head1 STRUCTURE

Gungho is comprised of three parts. A Provider, which provides Gungho with
requests to process, a Handler, which handles the fetched page, and an
Engine, which controls the entire process.

There are also "hooks". These hooks can be registered from anywhere by
invoking the register_hook() method. They are run at particular points,
which are specified when you call register_hook().

All components (engine, provider, handler) are overridable and switcheable.
However, do note that if you plan on customizing stuff, you should be aware
that Gungho uses Class::C3 extensively, and hence you may see warnings about
the code you use.

=head1 CONFIGURATION OPTIONS

=over 4

=item debug

   ---
   debug: 1

Setting debug to a non-zero value will trigger debug messages to be displayed.

=back

=head1 COMPONENTS

Components add new functionality to Gungho. Components are loaded at
startup time from the config file / hash given to Gungho constructor.

  Gungho->run({
    components => [
      'Throttle::Simple'
    ],
    throttle => {
      max_interval => ...,
    }
  });

Components modify Gungho's inheritance structure at run time to add
extra functionality to Gungho, and therefore should only be loaded
before starting the engine.

Here are some available components. Checkout the distribution for a current,
complete list:

=over 4

=item Authentication::Basic

Handles basic HTTP auth automatically.

=item BlockPrivateIP

Block hostnames that resolve to private IP addresses.

=item Cache

Adds cache supports to Gungho.

=item RobotRules

Handles collecting, parsing robots.txt, as well rejecting requests based on 
the rules provided from it.

=item RobotsMETA

Handles parsing Robots META information embedded in HTML E<lt>metaE<gt> tags

=item Scraper

Allows you to use Web::Scraper from within Gungho.

=item Throttle::Domain

Throttles requests based on the number of requests sent to a domain.

=item Throttle::Simple

Throttles requests based on the total number of requests being sent 

=back

=head1 INLINE

If you're looking into simple crawlers, you may want to look at Gungho::Inline,

  Gungho::Inline->run({
    provider => sub { ... },
    handler  => sub { ... }
  });

See the manual for Gungho::Inline for details.

=head1 HOOKS

Currently available hooks are:

=head2 engine.send_request

=head2 engine.handle_response

=head1 METHODS

=head2 component_base_class

Used for Class::C3::Componentised

=head1 HOW *NOT* TO USE Gungho

One last note about Gungho - Don't use it if you are planning on accessing
a single url -- It's usually not worth it, so you might as well use
LWP::UserAgent or an equivalent module.

Gungho's event driven engine works best when you are accessing hundreds,
if not thousands of urls. It may in fact be slower than using LWP::UserAgent
if you are accessing just a single url.

Of course, you may wish to utilize features other than speed that Gungho 
provides, so at that point, it's simply up to you.

=head1 CODE

You can obtain the current code base from

  http://gungho-crawler.googlecode.com/svn/trunk

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 CONTRIBUTORS

=over 4

=item Kazuho Oku

=item Keiichi Okabe

=back

=head1 SEE ALSO

L<Gungho::Inline|Gungho::Inline>
L<Gungho::Component::RobotRules|Gungho::Component::RobotRules>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
