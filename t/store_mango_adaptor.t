use Mojo::Base -strict;

use Test::More;

use Mango::BSON ':bson';
use Mango;
# use Mojo::IOLoop;

use Data::Dumper 'Dumper';
use Try;

# use Carp::Always;

use_ok 'EzyApp::Store::Mango::Adaptor';

use_ok 'EzyApp::Test::Model::User';

my $mango = Mango->new('mongodb://127.0.0.1/ezyapp_test');
my $users = $mango->db->collection('users');

try{ $users->drop() };


my $adap = EzyApp::Store::Mango::Adaptor->new( collection => $users );
ok $adap, 'new adaptor';

my $model = EzyApp::Test::Model::User->new;
ok $model, 'empty model';

# $model->store($adap);
# $model->update(sub {
#     my ($err, $model_ref) = @_;
#     is $err->{id}, 'not-found', 'not found error';
#     Mojo::IOLoop->stop;
# });
# Mojo::IOLoop->start;

$model = EzyApp::Test::Model::User->new(54321);
ok $model, 'new with id only';
ok $model->id, 'model id';

$model = EzyApp::Test::Model::User->new( store => $adap );
ok $model, 'new model with hash no record';

$model = EzyApp::Test::Model::User->new(
    store => $adap,
    record => { name => 'Fred' },
);
ok $model, 'new model with hash no id';

$model = EzyApp::Test::Model::User->new({
    store => $adap,
    record => { name => 'Fred' },
});
ok $model, 'new model with hashref no id';

$model = EzyApp::Test::Model::User->new(
    store => $adap,
    record => { id => 7654321, name => 'Fred' },
);
ok $model, 'new model with id (not _id) in hash';

$model = EzyApp::Test::Model::User->new({
    store => $adap,
    record => { id => 7654321, name => 'Fred' },
});
ok $model, 'new model with id (not _id) in hashref';

$model = EzyApp::Test::Model::User->new({
    store => $adap,
    record => { _id => 7654321, name => 'Fred' },
});
ok $model, 'new model with _id in hashref';

$model = EzyApp::Test::Model::User->new({
    store => $adap,
    record => { id => 7654321, name => 'Fred', 'email' => 'fred@rubblerock.com'  },
});
ok $model, 'new model with hashref';


my %record = %{$model->record};
$record{id} = delete $record{_id};
is_deeply $model->view, \%record, 'default view';

delete $record{email};
is_deeply $model->view([qw!name!]), \%record, 'custom view';


$model = EzyApp::Test::Model::User->new(
    store => $adap,
    record => { name => 'Fred' },
);

$model->save(sub{
    my ($err, $model_ref) = @_;
    ok $model->id, 'model id';
    is $model->get('name'), 'Fred', 'model name';

    my $model_clone = EzyApp::Test::Model::User->new(
        store => $adap,
        record => { _id => $model->id }
    );

    $model_clone->fetch(sub{
        my ($err, $model_clone_ref) = @_;
        is $model_clone_ref->get('name'), 'Fred', 'model name';

        $model->update({ surname => 'Flintstone' }, sub{
            my ($err, $model_ref) = @_;
            warn Dumper($err) if $err;
            is $model_ref->get('surname'), 'Flintstone', 'model surname';

            $model->save({ email => 'fred@rubblerock.com' }, sub{
                my ($err, $model_ref) = @_;
                is $model_ref->get('email'), 'fred@rubblerock.com', 'save with changes';

                my $id = bson_oid();
                $model->id($id);
                is $model->id, $id, 'set id';

                my $model_dodgy = EzyApp::Test::Model::User->new(
                    store => $adap,
                    record => { _id => 'nah!' }
                );
                $model_dodgy->fetch(sub{
                    my ($err, $model_what) = @_;
                    ok !$model_what, 'no model';

                    $model_dodgy->update(sub{
                        my ($err, $model_what) = @_;
                        is $err, 'Invalid object id: "nah!"', 'Invalid object';

                        $model_dodgy = EzyApp::Test::Model::User->new(
                            store => $adap,
                            record => { _id => bson_oid() }
                        );
                        $model_dodgy->update(sub{
                            my ($err, $model_what) = @_;
                            ok !$model_what, 'no model';
                            is $err->{id}, 'not-found', 'err id: not-found';
                            is $err->{model}->id,  $model_dodgy->id, 'err inc model';
                            Mojo::IOLoop->stop;
                        });
                    });
                });
            });
        });
    });
});
Mojo::IOLoop->start;

done_testing();
