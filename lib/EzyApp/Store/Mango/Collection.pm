package EzyApp::Store::Mango::Collection;
use Moose;
use Mango::BSON ':bson';

use EzyApp::Store::Mango::Adaptor;
use EzyApp::Store::Mango::Model;

=header EzyApp::Store::Mango::Collection

  $models = EzyApp::Store::Mango::Collection->new(
    collection => $mango_collection,
    class => 'EzyApp::Model::User'
  );

  $doc = $models->get($doc_id);
  $doc = $models->create($doc_data);

=cut

has collection => ( is => 'ro' );
has class => ( is => 'ro', isa => 'Str', default => 'EzyApp::Store::Mango::Model' );

has adaptor => (
  is => 'ro', lazy => 1,
  default => sub {
    my ($self) = @_;
    EzyApp::Store::Mango::Adaptor->new(collection => $self->collection);
  }
);


sub create{
  my ($self, $doc) = @_;
  my $class = $self->class;
  # my %args = ( collection => $self->collection );
  my %args = ( store => $self->adaptor );
  $args{record} = $doc if $doc;
  $class->new(%args);
}


sub get{
  my $callback = pop if ref $_[-1] eq 'CODE';
  my ($self, $id) = @_;
  $id = { _id => $id } if ref $id ne 'HASH';
  if ($callback){
    $self->collection->find_one( $id, sub{
      my ($coll, $err, $doc) = @_;
      $doc = $self->create($doc) if $doc;
      $callback->($err, $doc);
    });
  } else {
    my $doc = $self->collection->find_one($id);
    $doc = $self->create($doc) if $doc;
  }
}

sub find{
  my $callback = pop if ref $_[-1] eq 'CODE';
  my ($self, $criteria, $projection, $sort) = @_;
  if ($callback){
    my $cursor = $self->collection->find( $criteria, $projection );
    $cursor = $cursor->sort($sort) if $sort;
    $cursor->all(sub{
      my ($ursor, $err, $docs) = @_;
      $docs = [map { $self->create($_) } @$docs];
      $callback->($err, $docs);
    });
  } else {
    my $cursor = $self->collection->find( $criteria, $projection );
    $cursor = $cursor->sort($sort) if $sort;
    [map { $self->create($_) } @{$cursor->all}];
  }
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

=item get_min_id

return the lowest id for a site

  $id = $store->get_min_id($site_id);
  $store->get_min_id($site_id, $callback);

=cut

sub get_min_id{
  my ($self, $site_id, $callback) = @_;
  return $self->_get_id($site_id, { 'site_id' => $site_id }, '$min', $callback);
}

=item get_max_id

return the highest id for a site

  $id = $store->get_max_id($site_id);
  $store->get_max_id($site_id, $callback);

=cut

sub get_max_id{
  my ($self, $site_id, $callback) = @_;
  return $self->_get_id($site_id, { 'site_id' => $site_id }, '$max', $callback);
}

sub _get_id{
  my ($self, $match, $op, $callback) = @_;
  if ($callback){
    $self->collection->aggregate(
      [
          { '$match' => $match },
          { '$group' => { _id => 0, id => { $op => '$id' } } }
      ],
      sub {
        my ($collection, $err, $cursor) = @_;
        my $result = $cursor->next if $cursor;
        $callback->($err, $result ? $result->{id} : undef);
      }
    );
  } else {
    my $results = $self->collection->aggregate(
        [
            { '$match' => $match },
            { '$group' => { _id => 0, id => { $op => '$id' } } }
        ]
    );
    #print Dumper($result);
    my $result = $results->next if $results;
    return $result->{id} if $result;
    return
  }
}

# sub _get_id{
#   my ($self, $site_id, $op, $callback) = @_;
#   if ($callback){
#     $self->collection->aggregate(
#       [
#           { '$match' => { 'site_id' => $site_id } },
#           { '$group' => { _id => 0, id => { $op => '$id' } } }
#       ],
#       sub {
#         my ($collection, $err, $cursor) = @_;
#         my $result = $cursor->next if $cursor;
#         $callback->($err, $result ? $result->{id} : undef);
#       }
#     );
#   } else {
#     my $results = $self->collection->aggregate(
#         [
#             { '$match' => { 'site_id' => $site_id } },
#             { '$group' => { _id => 0, id => { $op => '$id' } } }
#         ]
#     );
#     #print Dumper($result);
#     my $result = $results->next if $results;
#     return $result->{id} if $result;
#     return
#   }
# }

no Moose;
__PACKAGE__->meta->make_immutable;


