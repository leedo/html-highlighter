package HTML::Highlighter;

use strict;
use warnings;

use HTML::Parser;
use Plack::Request;
use Plack::Util::Accessor qw/param callback/;

use parent 'Plack::Middleware';

use 5.008_001;
our $VERSION = "0.02";
$VERSION = eval $VERSION;

sub call {
  my ($self, $env) = @_;

  my $res = $self->app->($env);
  return $res unless $res->[0] == 200 and $res->[2];

  my $h = Plack::Util::headers($res->[1]);
  return $res unless $h->get("Content-Type") =~ /html/i;

  my $req = Plack::Request->new($env);

  $self->callback->($env) if $self->callback;

  my $highlights = do {
    if ($env->{'psgix.highlight'}) {
      $env->{'psgix.highlight'};
    } else {
      $req->parameters->{ $self->param || "highlight" };
    }
  };

  return $res unless $highlights;

  my @highlights = split /\s+/, $highlights;

  my $html;
  my $p = HTML::Parser->new(
    api_version => 3,
    handlers => {
      default => [ sub { $html .= $_[0] }, "text" ],
      text => [ 
        sub { for (@highlights) {
                $_[0] =~ s/($_)/<span class="highlight">$1<\/span>/gi;
              }
              $html .= $_[0] }, "text" ],
      end_document => [ sub { $res->[2] = [$html];
                        $h->set('Content-Length' => length $html) }],
    }
  );

  if (ref $res->[2] eq "ARRAY") {
    Plack::Util::foreach($res->[2], sub { $p->parse($_[0]) });
  } elsif ($res->[2]->can("getline")) {
    $p->parse_file($res->[2]);
  }

  return $res;
}

1;

__END__
=head1 NAME

HTML::Highlighter - PSGI middleware to highlight text in an HTML response

=head1 SYNOPSIS

    use Plack::Builder;
    use HTML::Highlighter;

    # highlight the "search" query param

    builder {
      enable "+HTML::Highlighter", param => "search";
      ...
      $app;
    };

    # or highlight the user stored in session

    builder {
      enable "+HTML::Highlighter", callback => sub {
        my $env = shift;
        $env->{'psgix.highlight'} = $env->{'psgix.session'}{user};
      };
      ...
      $app;
    };

=head1 DESCRIPTION

The C<HTML::Highlighter> module is a piece of PSGI middleware that will inspect
an HTML response and highlight parts of the page based on a query parameter or
other request data. This is very much like what Google does when you load a
page from their cache. Any text that matches your original query is highlighted.

    <span class="highlight">[matching text]</span>

This module also includes a javascript file called highlighter.js which gives
you a class with methods to jump (scroll) through the highlights.

=head1 CONSTRUCTOR PARAMETERS

=over

=item B<param>

This option allows you to specify a query parameter to be used for
the highlighting. For example, if you specify "search" as the param, each
response will look for a query parameter called "search" will highlight
that value in the response.

=item B<callback>

This option lets you specify a function that will be called on each request
to generate the text used for highlighting. The function will be passed the
$env hashref, and should set 'psgix.highlight' on it. This value will be used
for the highlighting. This could be useful if you want to highlight a username
that is stored in a session, or something similar.

=back

=head1 SEE ALSO

L<Plack::Builder>

L<HTML::Parser>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 Lee Aylward <leedo at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Lee Aylward, <leedo@cpan.org>

=cut
