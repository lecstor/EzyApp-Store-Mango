package EzyApp::Store::Mango::Collection;
use Moose;
use Mango::BSON ':bson';

use EzyApp::Store::Mango::Adaptor;
use EzyApp::Store::Mango::Model;

use Promises qw(deferred);

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


sub count{
  my $callback = pop if ref $_[-1] eq 'CODE';
  my ($self) = @_;
  if ($callback){
    $self->collection->find->count(sub{
      my ($coll, $err, $count) = @_;
      $callback->($err, $count);
    });
  } else {
    return $self->collection->find->count;
  }
}

sub promise_get{
  my ($self, $id) = @_;
  my $deferred = deferred;
  $self->get($id, sub{
    my ($err, $doc) = @_;
    return $deferred->reject($err) if $err;
    $doc
      ? $deferred->resolve($doc)
      : $deferred->reject("doc id: $id not found")
  });
  return $deferred->promise;
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

=item find

  my $results = $coll->find_cursor($criteria, $projection, $sort, $batch_size);

sets batch size to 1,000. MongoDB cursors time out after 10mins and
each batch gets a new cursor.

=cut

sub find{
  my $callback = pop if ref $_[-1] eq 'CODE';
  my ($self, $criteria, $projection, $sort, $batch_size) = @_;
  if ($callback){
    my $cursor = $self->collection->find( $criteria, $projection );
    $cursor = $cursor->sort($sort) if $sort;
    $cursor = $cursor->batch_size($batch_size || 1000);
    $cursor->all(sub{
      my ($cursor, $err, $docs) = @_;
      $docs = [map { $self->create($_) } @$docs];
      $callback->($err, $docs);
    });
  } else {
    my $cursor = $self->collection->find( $criteria, $projection );
    $cursor = $cursor->sort($sort) if $sort;
    $cursor = $cursor->batch_size($batch_size || 1000);
    [map { $self->create($_) } @{$cursor->all}];
  }
}

=item find_cursor

  my $cursor = $coll->find_cursor($criteria, $projection, $sort, $batch_size);

sets batch size to 1,000. MongoDB cursors time out after 10mins and
each batch gets a new cursor.

http://docs.mongodb.org/manual/core/cursors/

=cut

sub find_cursor{
  my ($self, $criteria, $projection, $sort, $batch_size) = @_;
  my $cursor = $self->collection->find( $criteria, $projection );
  $cursor = $cursor->sort($sort) if $sort;
  $cursor = $cursor->batch_size($batch_size || 1000);
  return $cursor;
}

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

sub get_latest{
  my ($self, $site, $callback) = @_;
  return $self->get_sorted($site, { _id => -1 }, $callback)
}

sub get_first{
  my ($self, $site, $callback) = @_;
  return $self->get_sorted($site, { _id => 1 }, $callback)
}

sub get_sorted{
  my ($self, $query, $sort, $callback) = @_;
  my $cursor = $self->collection
    ->find(ref $query ? $query : { site => $query })
    ->sort($sort)
    ->limit(1);
  if ($callback){
    if ($cursor){
      $cursor->next(sub{
        my ($cursor, $err, $doc) = @_;
        $doc = $self->create($doc) if $doc;
        $callback->($err, $doc);
      });
    } else {
      $callback->();
    }
  } else {
    return unless $cursor;
    my $doc = $cursor->next;
    $doc = $self->create($doc) if $doc;
  }
}


no Moose;
__PACKAGE__->meta->make_immutable;


