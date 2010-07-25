use strict;
use Plack::App::File;
use HTML::Highlighter;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

my $app = Plack::App::File->new(root => "t");
$app = HTML::Highlighter->wrap($app, param => "highlight");

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
