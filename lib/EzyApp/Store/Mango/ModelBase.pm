package EzyApp::Store::Mango::ModelBase;
use Moose;
use Mango::BSON ':bson';

=header EzyApp::Store::Mango::ModelBase

Base for models using L<EzyApp::Store::Mango>

=cut

has record => (
  is => 'rw', isa => 'HashRef',
  default => sub {{}},
  trigger => \&clear_view_attributes,
);

has store => ( is => 'rw' );

=item view_attributes

a list of properties to be included in the view.

The default implementation will ignore properties
beginning with an underscore.

=cut

has view_attributes => (
    is => 'ro', isa => 'ArrayRef',
    lazy => 1, default => sub {
        my %ob = %{shift->record};
        # don't include properties beginning with an underscore
        [map { /^_/ ? () : $_ } keys %ob]
    },
    clearer => "clear_view_attributes"
);

=item new

Create a model instance with only an id for fetching.

    $model = $model_class->new(54321);

Alternatively..

    $model_class->new(record => { _id => 54321 });

Create a model instance with changes for updating.

    $model_class->new(
        id => 43215,
        name => 'Spock',
        email => 'spock@enterprise.com',
    );

    $model_class->new();

=cut

sub BUILDARGS{
  my $class = shift;
  return {} unless @_;

  if ( @_ == 1 && !ref $_[0] ) {
    # use a single scalar as the id
    return { record => {_id => $_[0] }};
  } else {
    if (@_ > 1){
      my %args = @_;
      # building a model with no data? oh well, ok.
      return \%args unless exists $args{record};

      # make sure the id goes in _id
      $args{record}{_id} = delete $args{record}{id} || $args{record}{_id};
      return \%args;

    } else {
      my $args = shift;
      # make sure the id goes in _id
      $args->{record}{_id} = delete $args->{record}{id} || $args->{record}{_id};
      return $args;
    }
  }
}

=item id

a shortcut for the id

=cut

sub id{
  my ($self, $id) = @_;
  return $self->record->{_id} unless $id;
  return $self->record->{_id} = $id;
}

=item get

get a property value

    $model->get('email');

=cut

sub get{
  my ($self, $property_name) = @_;
  $self->record->{$property_name};
}

=item set

set a property value

    $model->set('email', 'picard@enterprise.com');

=cut

sub set{
  my ($self, $property_name, $value) = @_;
  $self->clear_view_attributes; # in case we're adding a new property
  $self->record->{$property_name} = $value;
}

=item view

returns the model document only including properties specified, or
if none are specified, then only those included in view_attributes().

    $model->view;
    $model->view(['_id',name','email']);

=cut

sub view{
  my ($self, $properties) = @_;
  if (!$properties){
    $properties = $self->view_attributes;
  }
  my $doc = {};
  foreach my $prop (@$properties){
    $doc->{$prop} = $self->record->{$prop};
  }
  $doc->{id} = $self->id;
  return $doc;
};

=item serialize_storage

returns a document suitable for storing in the database.
This method is called internally for saves and updates.
By default this method returns a copy of the model document.

=cut

sub serialize_storage{
  return \%{shift->record};
}

=item update

Use the model's record as an atomic update.

  $model->update(sub{ say 'Saved!' });

Update the model's record, then use it as an atomic update.

  $model->update(
    { name => 'Jon' },
    sub{ say 'Updated and Saved!' }
  );

=cut

sub update{
  my $self = shift;
  $self->store->update($self, @_);
}

=item save

  $callback = sub{ my ($err, $model) = @_; }

Save the models record to the store.

  $model->save($callback);

Update the model's record and save it.

  $model->save(
    { name => 'Jon' },
    $callback
  );

=cut

sub save{
  my $self = shift;
  $self->store->save($self, @_);
}

=item fetch

  $callback = sub{ my ($err, $model) = @_; }

Refresh the model's record from the store.

  $model->fetch($callback);

=cut

sub fetch{
  my $self = shift;
  $self->store->fetch($self, @_);
}

no Moose;
__PACKAGE__->meta->make_immutable;
