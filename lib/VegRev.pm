package VegRev;

use v5.14;
use feature 'unicode_strings';
use utf8;
use common::sense;

use Dancer ':syntax';
use Dancer::Plugin::Passphrase;

use Time::HiRes qw/time/;

use HTML::Tidy;
use Data::Structure::Util qw/unbless/;

use Dancer::Plugin::Database;
use Data::Dump qw/dump/;
use POSIX qw/ceil floor/;

use Carp;
use VegRev::User;
use VegRev::Forum;
use VegRev::Thread;
use VegRev::Inbox;
use VegRev::Chat;
use VegRev::Gallery;

use VegRev::ViewHelpers;
use VegRev::Misc;


our $VERSION = '0.0.1';

set environment => 'sensitive';
 
# Loads the viewer, should get the user ID from the cookie
# Should also do some authentication here
hook 'before' => sub {
    if (!session('user_id')) {
        warn "hello";
        # my $viewer = VegRev::User->new({ id => 1 })->load_extra;
        # $viewer->store_session;
    } else {
        my $viewer = VegRev::User->new({ id => session('user_id') })->load_extra;
        $viewer->store_session;
    }    
};


# Add the Plack::Middleware::Assets used in all routes
hook 'before_template' => sub {
    my $tokens = shift;

    # Xslate seems to get horribly confused with session stuff
    ($tokens->{viewer}) = unbless session();

    $tokens->{theme}        = session('theme');
    $tokens->{user_name}    = session('user_name');
    $tokens->{recent}       = session('recent_threads');

    $tokens->{tags}   = VegRev::Misc::list_tags();
    $tokens->{online} = VegRev::Misc::currently_online();

    $tokens->{request} = request;


#    $tokens->{base_css} = request->env->{'psgix.assets'}->[0];
#    $tokens->{base_js}  = request->env->{'psgix.assets'}->[1];

};


# Make sure we commit any open transactions. The entire request depends on it.
hook 'after' => sub {
    eval    { database->commit; };
    if ($@) { die "Committing Transaction Failed: $@"; }
};



# GET Routes
#####################


# Matches / and /:page
get qr{/(\d+)?/?$} => sub {
    my ($page) = splat;

    $page = $page // 1;
    my $per_page = 30;

    my $forum = VegRev::Forum::new_from_tag({
        tag    => undef,
        offset => ($page * $per_page) - $per_page,
        limit  => $per_page,
    });

    template 'forum', {
        postform => { header => 'Start a new thread' },
        active   => { forum => 'active'},
        forum    => $forum,
        template => 'forum',
    };
};


# Matches /thread/:thread_id-:url_slug/:page - URL slug is ignored.
get qr{/thread/(\d+).+?/?(\d+)?$} => sub {
    my ($thread_id, $page) = splat;

    $page = $page // 1;
    my $per_page = 30;

    my $thread = VegRev::Thread::new_from_id({
        id     => $thread_id,
        offset => ($page * $per_page) - $per_page,
        limit  => $per_page,
    });

    $thread->mark_as_read();

    template 'thread', {
        postform => { header => 'Post a reply' },
        active   => { forum => 'active' },
        template => 'thread',
        thread   => $thread
    };
};


# Matches /inbox/:page
get qr{/inbox/?(\d+)?/?$} => sub {
    my ($page) = splat;

    $page = $page // 1;
    my $per_page = 50;

    my $inbox = VegRev::Inbox->new({
        user_id => session('user_id'),
        offset  => ($page * $per_page) - $per_page,
        limit   => $per_page,
    });

    template 'inbox', {
        active   => { inbox => 'active'},
        inbox    => $inbox,
        template => 'inbox',
    };
};


# Matches /chat/:page
get qr{/chat/(\d+)/?(\d+)?/?$} => sub {
    my ($chat_id, $page) = splat;

    $page = $page // 1;
    my $per_page = 50;

    my $thread = VegRev::Chat::new_from_id({
        chat_id => $chat_id,
        user_id => session->{user_id},
        offset  => ($page * $per_page) - $per_page,
        limit   => $per_page,
    });

    template 'chat', {
        active   => { inbox => 'active'},
        template => 'thread',
        thread   => $thread
    };
};


# Matches /gallery/:page
get qr{/gallery/?(\d+)?/?$} => sub {
    my ($chat_id, $page) = splat;

    $page = $page // 1;
    my $per_page = 50;

    my $gallery = VegRev::Gallery::new_from_tag({
        offset  => ($page * $per_page) - $per_page,
        limit   => $per_page,
    });

    template 'gallery', {
        active   => { gallery => 'active'},
        recent   => session('recent_threads'),
        template => 'gallery',
        gallery  => $gallery
    };
};


# Matches /profile/:user_name
get qr{/profile/(\w+)/?$} => sub {
    my ($user_name) = splat;

    my $sth = database->prepare(q{
        SELECT *
        FROM user
        WHERE user_name = ?
    });

    $sth->execute($user_name);
    my $user = $sth->fetchall_hashref('id');

    # Send to 404 if user doesn't exist
    unless (scalar keys %{$user}) {
        return pass();
    }

    template 'user', {
        recent   => session('recent_threads'),
        template => 'profile',
        user     => values %{$user},
    };

};





# POST Routes
################


post qr{/thread/(\d+).+?/?$} => sub {
    my ($thread_id) = splat;

    template 'thread', {
        template => 'thread',
    };
};


post qr{/post/?$} => sub {
    my %params = params;

    # Try and clean up the browser supplied "WYSIWYG" mess
    if (defined $params{message}) {
        my $tidy = HTML::Tidy->new({
            char_encoding               => 'utf8',
            input_encoding              => 'utf8',
            output_encoding             => 'utf8',
            newline                     => 'LF',
            sort_attributes             => 'alpha',
            doctype                     => 'omit',
            tidy_mark                   => 0,
            bare                        => 0,
            clean                       => 0,
            fix_backslash               => 1,
            indent                      => 1,
            break_before_br             => 1,
            merge_divs                  => 1,
            merge_spans                 => 1,
            drop_empty_paras            => 1,
            drop_proprietary_attributes => 1,
            logical_emphasis            => 1,
            quote_ampersand             => 1,
            quote_nbsp                  => 1,
            show_body_only              => 1,
            word_2000                   => 1,
        });

        $tidy->ignore( type => 1, type => 2 );

        $params{tidy_message} = $tidy->clean($params{message});
    }

    croak dump \%params;

};


post qr{/login/?$} => sub {

    if (!param('email') || !param('password')) {
        return undef;
    }

    # FIXME: Fugly
    my $user = VegRev::User->new_from_email({ email=> param('email') });

    # We upgrade the password if old_password exists
    if (!$user->password) {
        my $hash = passphrase(setting('password_key') . "|" . param('password'))->generate_hash({scheme=>'MD5'})->hash_hex;

        if ($hash eq $user->{old_password}) {
            my $new_hash = passphrase(param('password'))->generate_hash({cost=>8});

            $user->password($new_hash);
            $user->save([qw(password)]);
        }
    }

    # We've upgraded the password if it's right
    if ( passphrase( param('password') )->matches( $user->password ) ) {
        $user->load_extra;
        $user->store_session;
    } else {
        # TODO: Error handling

    }
};




# Misc Routes
################

# Redirects to a specific message when given a message id
get qr{/message/?(\d+)?/?$} => sub {
    my ($message_id) = splat;

    # Calculate how many messages are before it in the same thread
    my $thread_sth = database->prepare(q{
        SELECT COUNT(*) as count, thread_id, url_slug
        FROM message
        LEFT JOIN thread ON thread_id = thread.id
        WHERE thread_id = (SELECT thread_id FROM message WHERE message.id = ? LIMIT 1)
        AND message.id <= ?
        AND message.deleted != 1
        LIMIT 1
    });
    $thread_sth->execute($message_id, $message_id);
    my $messages = $thread_sth->fetchall_arrayref({})->[0];

    # TODO - this should be in settings somewhere...
    my $per_page   = 30;
    my $start_page = floor($messages->{count} / $per_page) + 1;

    my $redirect_page = '/thread/' . $messages->{thread_id} . '-' . $messages->{url_slug};

    # Page one threads don't need the page number
    $redirect_page .= '/' . $start_page    if $start_page > 1;

    # First message in thread doesn't need an ID
    $redirect_page .= '#' . $message_id    if $messages->{count} > 1;

    return redirect $redirect_page;
};




1;
