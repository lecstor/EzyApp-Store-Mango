package EzyApp::Store::Mango::MojoliciousPlugin;
use Mojo::Base 'Mojolicious::Plugin';

use Mango;
use Mango::BSON ':bson';

use EzyApp::Store::Mango::Collection;
use EzyApp::Store::Mango::Model;
use EzyApp::Store::Mango;

sub register {
  my ($self, $app) = @_;

  $app->attr(mango => sub {
    Mango->new($app->config->{mongodb}{connect});
  });

  $app->helper('mango' => sub { shift->app->mango });

  $app->helper('dbc' => sub { shift->mango->db->collection(shift) });

  $app->attr(model => sub {
    EzyApp::Store::Mango->new(database => $app->mango->db);
  });

  $app->helper('model' => sub { shift->app->model });

}

1;
