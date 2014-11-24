package EzyApp::Store::Mango::Collection;
use Moose;
use Mango::BSON ':bson';

use EzyApp::Store::Mango::Adaptor;

=header EzyApp::Store::Mango::Collection

  $models = EzyApp::Store::Mango::Collection->new(
    database => $mongodb,
    name => 'users',
    class => 'EzyApp::model::Users'
  );

  $doc = $models->get($doc_id);
  $doc = $models->create($doc_data);

=cut

has collection => ( is => 'ro' );
has model_class => ( is => 'ro', isa => 'Str' );

has adaptor => (
  is => 'ro', lazy => 1,
  default => sub {
    my ($self) = @_;
    EzyApp::Store::Mango::Adaptor->new(collection => $self->collection);
  }
);


sub get{
  my ($self, $id, $callback) = @_;
  $id = { _id => $id } if ref $id ne 'HASH';
  $self->collection->find_one( $id, sub{
    my ($coll, $err, $doc) = @_;
    $doc = $self->create($doc) if $doc;
    $callback->($err, $doc);
  });
}

sub create{
  my ($self, $doc) = @_;
  my $class = $self->class;
  # my %args = ( collection => $self->collection );
  my %args = ( store => $self->adaptor );
  $args{record} = $doc if $doc;
  return $class->new(%args);
}

# sub update{
#     my ($self, $id, $update, $callback) = @_;
#     $self->collection->find_and_modify({
#       query => { _id => $id },
#       update => { '$set' => $update }
#     }, sub{
#         shift @_;
#         $callback->(@_);
#     });
# }


no Moose;
__PACKAGE__->meta->make_immutable;


