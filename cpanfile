requires 'Module::Install';
requires 'Module::CPANfile', '0.9034';

requires 'Clone';
requires 'Mango';
requires 'Moose';
requires 'Try';

on 'test' => sub {
  requires 'Test::More';
  requires 'Devel::Cover';
};

