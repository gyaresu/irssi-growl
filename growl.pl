#!/usr/bin/env perl -w
#
# This is an Irssi script to send out Growl notifications over the network
# using growlnotify. It is inspired by the original Growl script by
# Nelson Elhage and Toby Peterson.

use strict;
use vars qw($VERSION %IRSSI);

use Irssi;

$VERSION = '1.0.0';
%IRSSI = (
  authors     =>  'Sorin Ionescu',
  contact     =>  'sorin.ionescu@gmail.com',
  name        =>  'Growl',
  description =>  'Sends out Growl notifications from Irssi',
  license     =>  'BSD',
  url         =>  'http://github.com/sorin-ionescu/irssi-growl',
);

# Notification Settings
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_message_public', 0);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_message_private', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_message_action', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_message_notice', 0);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_message_invite', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_hilight', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_notifylist', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_server', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_channel_join', 0);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_channel_mode', 0);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_channel_topic', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_dcc_request', 1);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_show_dcc_closed', 1);

# Network Settings
Irssi::settings_add_str($IRSSI{'name'}, 'growl_net_host', 'localhost');
Irssi::settings_add_str($IRSSI{'name'}, 'growl_net_port', '23053');
Irssi::settings_add_str($IRSSI{'name'}, 'growl_net_pass', 'password');

# Icon Settings
Irssi::settings_add_str($IRSSI{'name'}, 'growl_net_icon', '$HOME/.irssi/icon.png');

# Sticky Settings
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_net_sticky', 0);
Irssi::settings_add_bool($IRSSI{'name'}, 'growl_net_sticky_away', 1);

sub cmd_help {
    Irssi::print('Growl can be configured with these settings:');
    Irssi::print('%WNotification Settings%n');
    Irssi::print('  %ygrowl_show_message_public%n : Notify on public message. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_message_private%n : Notify on private message. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_message_action%n : Notify on action message. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_message_notice%n : Notify on notice message. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_message_invite%n : Notify on channel invitation message. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_hilight%n : Notify on nick highlight. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_notifylist%n : Notify on notification list connect and disconnect. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_server%n : Notify on server connect and disconnect. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_channel_join%n : Notify on channel join. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_channel_mode%n : Notify on channel modes change. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_channel_topic%n : Notify on channel topic change. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_dcc_request%n : Notify on DCC chat request. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_show_dcc_closed%n : Notify on DCC chat/file transfer closing. (ON/OFF/TOGGLE)');
    
    Irssi::print('%WNetwork Settings%n');
    Irssi::print('  %ygrowl_net_host%n : Set the Growl server host.');
    Irssi::print('  %ygrowl_net_port%n : Set the Growl server port.');
    Irssi::print('  %ygrowl_net_pass%n : Set the Growl server password.');
    
    Irssi::print('%WIcon Settings%n');
    Irssi::print('  %ygrowl_net_icon%n : Set the Growl notification icon path.');
    
    Irssi::print('%WSticky Settings%n');
    Irssi::print('  %ygrowl_net_sticky%n : Set sticky notifications. (ON/OFF/TOGGLE)');
    Irssi::print('  %ygrowl_net_sticky_away%n : Set sticky notifications only when away. (ON/OFF/TOGGLE)');
}

sub get_sticky {
    my ($server);
    $server = Irssi::active_server();
    if (Irssi::settings_get_bool('growl_net_sticky_away')) {
        if (!$server->{usermode_away}) {
            return 0;
        } else {
            return 1;
        }
    } else {
        return Irssi::settings_get_bool('growl_net_sticky');
    }
}

sub growl_notify {
    my $GrowlHost     = Irssi::settings_get_str('growl_net_host');
    my $GrowlPort     = Irssi::settings_get_str('growl_net_port');
    my $GrowlPass     = Irssi::settings_get_str('growl_net_pass');
    my $GrowlIcon     = Irssi::settings_get_str('growl_net_icon');
    my $GrowlSticky   = get_sticky() == 1 ? " --sticky" : "";
    my $AppName       = "Irssi";
    
    my ($event, $title, $message, $priority) = @_;
    
    $message =~ s/(")/\\$1/g;

    system(
        "growlnotify" 
        . " --name \"$AppName\""
        . " --host \"$GrowlHost\""
        . " --port \"$GrowlPort\""
        . " --password \"$GrowlPass\""
        . " --image \"$GrowlIcon\""
        . " --priority \"$priority\""
        . " --identifier \"$event\""
        . " --title \"$title\""
        . " --message \"$message\""
        . "$GrowlSticky"
        . " >> /dev/null 2>&1"
    );
}

sub sig_message_public {
    return unless Irssi::settings_get_bool('growl_show_message_public');
    my ($server, $msg, $nick, $address, $target) = @_;
    growl_notify("Channel", "Public Message", "$nick: $msg", 0);
}

sub sig_message_private {
    return unless Irssi::settings_get_bool('growl_show_message_private');
    my ($server, $msg, $nick, $address) = @_;
    growl_notify("Message", "Private Message", "$nick: $msg", 1);
}

sub sig_message_dcc {
    return unless Irssi::settings_get_bool('growl_show_message_private');
    my ($dcc, $msg) = @_;
    growl_notify("DCC", "Private Message", "$dcc->{nick}: $msg", 1);
}

sub sig_ctcp_action {
    return unless Irssi::settings_get_bool('growl_show_message_action');
    my ($server, $args, $nick, $address, $target) = @_;
    growl_notify("Message", "Action Message", "$nick: $args", 1);
}

sub sig_message_dcc_action {
    return unless Irssi::settings_get_bool('growl_show_message_action');
    my ($dcc, $msg) = @_;
    growl_notify("DCC", "Direct Chat Action Message", "$dcc->{nick}: $msg", 1);
}

sub sig_event_notice {
    return unless Irssi::settings_get_bool('growl_show_message_notice');
    my ($server, $data, $source) = @_;
    $data =~ s/^[^:]*://;
    growl_notify("Message", "Notice Message", "$source: $data", 1);
}

sub sig_message_invite {
    return unless Irssi::settings_get_bool('growl_show_message_invite');
    my ($server, $channel, $nick, $address) = @_;
    growl_notify(
        "Message",
        "Channel Invitation",
        "$nick has invited you to join $channel.",
        1
    );
}

sub sig_print_text {
    return unless Irssi::settings_get_bool('growl_show_hilight');
    my ($dest, $text, $stripped) = @_;
    my $nick;
    my $msg;
    if ($dest->{level} & MSGLEVEL_HILIGHT) {
        $stripped =~ /^\s*\b(\w+)\b[^:]*:\s*(.*)$/;
        $nick = $1;
        $msg = $2;
        growl_notify("Hilight", "Highlighted Message", "$nick: $msg", 2);
    }
}

sub sig_notifylist_joined {
    return unless Irssi::settings_get_bool('growl_show_notifylist');
    my ($server, $nick, $user, $host, $realname, $awaymsg) = @_;
    growl_notify(
        "Notify List",
        "Friend Connected",
        ("$realname" || "$nick") . " has connected to $server->{chatnet}.",
        0
    );
}

sub sig_notifylist_left {
    return unless Irssi::settings_get_bool('growl_show_notifylist');
    my ($server, $nick, $user, $host, $realname, $awaymsg) = @_;
    growl_notify(
        "Notify List",
        "Friend Disconnected",
        ("$realname" || "$nick") . " has disconnected from $server->{chatnet}.",
        0
    );
}

sub sig_server_connected {
    return unless Irssi::settings_get_bool('growl_show_server');
    my($server) = @_;
    growl_notify(
        "Server", 
        "Server Connected",
        "Connected to network $server->{chatnet}.",
        0
    );
}

sub sig_server_disconnected {
    return unless Irssi::settings_get_bool('growl_show_server');
    my($server) = @_;
    growl_notify(
        "Server",
        "Server Disconnected",
        "Disconnected from network $server->{chatnet}.",
        0
    );
}

sub sig_channel_joined {
    return unless Irssi::settings_get_bool('growl_show_channel_join');
    my ($channel) = @_;
    growl_notify(
        "Channel",
        "Channel Joined",
        "Joined channel $channel->{name}.",
        0
    );
}

sub sig_channel_mode_changed {
    return unless Irssi::settings_get_bool('growl_show_channel_mode');
    my ($channel) = @_;
    growl_notify(
        "Channel",
        "Channel Modes",
        "$channel->{name}: $channel->{mode}",
        0
    );
}

sub sig_channel_topic_changed {
    return unless Irssi::settings_get_bool('growl_show_channel_topic');
    my ($channel) = @_;
    growl_notify(
        "Channel",
        "Channel Topic",
        "$channel->{name}: $channel->{topic}",
        0
    );
}

sub sig_dcc_request {
    return unless Irssi::settings_get_bool('growl_show_dcc_request');
    my ($dcc, $sendaddr) = @_;
    my $title;
    my $message;
    if ($dcc->{type} =~ /CHAT/) {
        $title = "Direct Chat Request";
        $message = "$dcc->{nick} wants to chat directly.";
    }
    if ($dcc->{type} =~ /GET/) {
        $title = "File Transfer Request";
        $message = "$dcc->{nick} wants to send you $dcc->{arg}.";
    }
    growl_notify("DCC", $title, $message, 0);
}

sub sig_dcc_closed {
    return unless Irssi::settings_get_bool('growl_show_dcc_closed');
    my ($dcc) = @_;
    my $title;
    my $message;
    if ($dcc->{type} =~ /GET|SEND/) {
        if ($dcc->{size} == $dcc->{transfd}) {
            if ($dcc->{type} =~ /GET/) {
                $title = "Download Complete";
            }
            if ($dcc->{type} =~ /SEND/) {
                $title = "Upload Complete";
            }
        }
        else {
            if ($dcc->{type} =~ /GET/) {
                $title = "Download Failed";
            }
            if ($dcc->{type} =~ /SEND/) {
                $title = "Upload Failed";
            }
        }
        $message = $dcc->{arg};
    }

    if ($dcc->{type} =~ /CHAT/) {
        $title = "Direct Chat Ended";
        $message = "Direct chat with $dcc->{nick} has ended.";
    }
    growl_notify("DCC", $title, $message, 0);
}

Irssi::command_bind('growl', 'cmd_help');

Irssi::signal_add_last('message public', \&sig_message_public);
Irssi::signal_add_last('message private', \&sig_message_private);
Irssi::signal_add_last('message dcc', \&sig_message_dcc);
Irssi::signal_add_last('ctcp action', \&sig_ctcp_action);
Irssi::signal_add_last('message dcc action', \&sig_message_dcc_action);
Irssi::signal_add_last('event notice', \&sig_event_notice);
Irssi::signal_add_last('message invite', \&sig_message_invite);
Irssi::signal_add_last('print text', \&sig_print_text);
Irssi::signal_add_last('notifylist joined', \&sig_notifylist_joined);
Irssi::signal_add_last('notifylist left', \&sig_notifylist_left);
Irssi::signal_add_last('server connected', \&sig_server_connected);
Irssi::signal_add_last('server disconnected', \&sig_server_disconnected);
Irssi::signal_add_last('channel joined', \&sig_channel_joined);
Irssi::signal_add_last('channel mode changed', \&sig_channel_mode_changed);
Irssi::signal_add_last('channel topic changed', \&sig_channel_topic_changed);
Irssi::signal_add_last('dcc request', \&sig_dcc_request);
Irssi::signal_add_last('dcc closed', \&sig_dcc_closed);

