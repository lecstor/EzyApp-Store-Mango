package EzyApp::Store::Mango::Adaptor;
use Moose;

use Mango::BSON ':bson';

use Data::Dumper 'Dumper';

use Try;

=header EzyApp::Store::Mango::Adaptor

simple access to MongoDB via the Mango driver.

=cut

has collection => ( is => 'ro' );

=item new

  EzyApp::Store::Mango::Adaptor->new(collection => $ezyapp_store_mango_collection);

=cut


=item update

  $model->update($callback);
  $model->update({ my => 'change' }, $callback);

Updates all properties currently set in the model.
ie If the model only has the _id and password properties
set, update will save the password property without
overwriting other properties.

=cut

sub update{
  my $cb = pop;
  my ($self, $model, $values) = @_;

  $values ||= {};
  foreach my $property_name (keys %$values){
    $model->set($property_name, $values->{$property_name});
  }

  # warn 'model update serialize_storage'.Data::Dumper->Dumper($model->serialize_storage);

  my $_id;
  try{ $_id = bson_oid $model->id };

  return $cb->('Invalid object id: "'.$model->id.'"') unless $_id;

  $self->collection->find_and_modify({
    query => { _id => $_id },
    update => { '$set' => $model->serialize_storage }, # atomic update
    new => bson_true, # return the modified doc
    # upsert => bson_true, # create doc if none found
  }, sub{
    my $coll = shift;
    my ($err, $doc) = @_;
    return $cb->({ id => 'not-found', model => $model }) unless $doc;
    return $cb->($err) if $err;

    $model->record($doc);

    $cb->($err, $model);
  });
}

=item save

  $model->save($callback);
  $model->save({ my => 'change' }, $callback);

Sets the stored record to the models value.

=cut

sub save{
  my $cb = pop;
  my ($self, $model, $values) = @_;
  $values ||= {};
  foreach my $property_name (keys %$values){
    $model->set($property_name, $values->{$property_name});
  }
  
  $self->collection->save($model->serialize_storage, sub{
    my ($coll, $err, $oid) = @_;
    $model->set('_id', $oid);
    $cb->($err, $model);
  });
}

=item fetch

refresh the object from the database

=cut

sub fetch{
  my ($self, $model, $callback) = @_;
  my $id = { _id => $model->id };
  $self->collection->find_one( $id, sub{
    my ($coll, $err, $doc) = @_;
    $model->record($doc) if $doc;
    $callback->($err, $doc ? $model : undef);
  });
}


no Moose;
__PACKAGE__->meta->make_immutable;

