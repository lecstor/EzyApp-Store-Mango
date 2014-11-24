package EzyApp::Store::Mango;
use Moose;
use EzyApp::Store::Mango::Collection;

=header EzyApp::Model

provides methods to controllers to get the work done.

=cut

has database => ( is => 'ro' );

has users => (
  is => 'ro', isa => 'EzyApp::Models', lazy => 1,
  default => sub{
    EzyApp::Store::Mango::Collection->new(
      collection => shift->database->collection('users')
    )
  }
);

has accounts => (
  is => 'ro', isa => 'EzyApp::Store::Mango::Collection', lazy => 1,
  default => sub{
    EzyApp::Store::Mango::Collection->new(
      collection => shift->database->collection('accounts')
    )
  }
);

has apikeys => (
  is => 'ro', isa => 'EzyApp::Store::Mango::Collection', lazy => 1,
  default => sub{
    EzyApp::Store::Mango::Collection->new(
      collection => shift->database->collection('apikeys')
    )
  }
);

no Moose;
__PACKAGE__->meta->make_immutable;




