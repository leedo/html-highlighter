use strict;
use Plack::App::File;
use HTML::Highlighter;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

my $file = Plack::App::File->new(root => "t");

# get the highlight from a param
#
my $app = HTML::Highlighter->wrap($file, param => "highlight");

test_psgi $app, sub {
  my $cb = shift;

  my $res = $cb->(GET "/foo.html?highlight=foo");
  is $res->code, 200;
  {
    local $/; 
    open my $highlighted, '<', 't/foo-highlighted.html';
    my $html = <$highlighted>;
    ok $res->content eq $html;
  }
};

# set highlight in callback
#
$app = HTML::Highlighter->wrap($file, callback => sub {
    my $env = shift;
    $env->{'psgix.highlight'} = "foo";
});

test_psgi $app, sub {
  my $cb = shift;

  my $res = $cb->(GET "/foo.html?highlight=foo");
  is $res->code, 200;
  {
    local $/; 
    open my $highlighted, '<', 't/foo-highlighted.html';
    my $html = <$highlighted>;
    ok $res->content eq $html;
  }
};


done_testing();
