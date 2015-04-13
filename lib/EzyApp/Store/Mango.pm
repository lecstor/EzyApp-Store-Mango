package EzyApp::Store::Mango;
use Moose;
use EzyApp::Store::Mango::Collection;

use EzyApp::Model::User;
use EzyApp::Model::Account;
use EzyApp::Model::APIKey;

our $VERSION = '0.01';

=head1 NAME

EzyApp::Model - provides methods to controllers to get the work done.

=head1 AUTHOR

Jason Galea <jason@ezyapp.com>

=cut

has database => ( is => 'ro' );

has users => (
  is => 'ro', isa => 'EzyApp::Store::Mango::Collection', lazy => 1,
  default => sub{
    EzyApp::Store::Mango::Collection->new(
      collection => shift->database->collection('users'),
      class => 'EzyApp::Model::User',
    )
  }
);

has accounts => (
  is => 'ro', isa => 'EzyApp::Store::Mango::Collection', lazy => 1,
  default => sub{
    EzyApp::Store::Mango::Collection->new(
      collection => shift->database->collection('accounts'),
      class => 'EzyApp::Model::Account',
    )
  }
);

has apikeys => (
  is => 'ro', isa => 'EzyApp::Store::Mango::Collection', lazy => 1,
  default => sub{
    EzyApp::Store::Mango::Collection->new(
      collection => shift->database->collection('apikeys'),
      class => 'EzyApp::Model::APIKey',
    )
  }
);

no Moose;
__PACKAGE__->meta->make_immutable;




