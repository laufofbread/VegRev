package VR;
use Dancer ':syntax';

our $VERSION = '0.0.1';

# Perl stuff
use common::sense;
use Time::HiRes qw/time/;

# Dancer Plugins
use Dancer::Plugin::Database;

# Extra Routes
use VR::Route;
#use VR::Route::Admin;
use VR::Route::Chat;
use VR::Route::Forum;
use VR::Route::Gallery;
use VR::Route::Mail;
use VR::Route::Member;
use VR::Route::Photo;
use VR::Route::Poll;
use VR::Route::Profile;
use VR::Route::Search;
use VR::Route::Shoutbox;
use VR::Route::Search;
use VR::Route::Tag;
use VR::Route::Thread;

# Modules for before filter (REFACTOR ME)
use VR::Model qw/users_online fill_session/;

hook 'before' => sub {
  # We are already in transactional mode
  
  # TODO - Add the login system.
  our $global = {};
  $global->{'start_time'}   = time();
  $global->{'users_online'} = users_online('15');

  fill_session('1');
};

hook 'after' => sub {
  # Make sure we commit any open transactions. The entire request depends on it.
  eval      { database->commit; };
  if ($@)   { die "Committing Transaction Failed: $@"; }
};


# Default route for 404
get qr{.*} => sub {
    status 'not_found';

    template 'index', {
        path => request->path
    };
};


true;
