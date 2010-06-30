package Plack::Middleware::Highlighter;

use strict;
use warnings;

use HTML::Parser;
use Plack::Request;
use Plack::Util::Accessor qw/param/;

use parent 'Plack::Middleware';

sub call {
  my ($self, $env) = @_;

  my $res = $self->app->($env);
  return $res unless $res->[0] == 200 and $res->[2];

  my $h = Plack::Util::headers($res->[1]);
  return unless $h->get("Content-Type") =~ /html/i;

  my $req = Plack::Request->new($env);
  my $highlight = $req->parameters->{ $self->param };
  return $res unless $highlight;

  my $html;
  my $p = HTML::Parser->new(
    api_version => 3,
    handlers => {
      default => [ sub { $html .= $_[0] }, "text" ],
      text => [ sub { $_[0] =~ s/($highlight)/<span class="highlight">$1<\/span>/gi;
                      $html .= $_[0] }, "text" ],
      end_document => [ sub { $res->[2] = [$html];
                        $h->set('Content-Length' => length $html) }],
    }
  );

  if (ref $res->[2] eq "CODE") {
    $p->parse($res->[2]);
  } elsif (ref $res->[2] eq "ARRAY") {
    Plack::Util::foreach($res->[2], sub { $p->parse($_[0]) });
  } elsif ($res->[2]->can("getline")) {
    $p->parse_file($res->[2]);
  }

  return $res;
}

1;
