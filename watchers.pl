#!/usr/bin/perl

package FA_Watchlog;

use warnings;
use strict;
use Carp;
use LWP 5.64;

# LWP globals
my $browser = LWP::UserAgent->new;
my @ns_headers = ( 'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:33.0) Gecko/20100101 Firefox/33.0',
	       'Accept' => 'text/html,/*/',
	       'Accept-Language' => 'en-US');

main(user=>$ARGV[0], debug=>1);
exit(0);

sub main {
    my (%args) = @_;
    my ($FAUser) = $args{'user'} || usage();
    
    my ($UID) = get_uid($FAUser);
    if (not defined $UID) {
	die("Invalid FA user");
    }


    print "Got UID $UID for user $FAUser...\n" if $args{'debug'};
    fetch_watchers(user=>$FAUser, uid=>$UID); 
}

sub usage {
    print "Usage: $0 username\n";
    exit;
}

# Get the user ID for a given nickname
sub get_uid {
    my ($user) = @_;

    my $response = $browser->get("http://www.furaffinity.net/user/$user", @ns_headers);
    check_response($response);

    if ($response->content =~ m/\/budslist\/\?name.*\&uid=(\d+)\&mode=watched_by/) {
	return int($1);
    } else {
	return undef;
    }

}

# Check if there was an issue in fetching the page
sub check_response {
    my ($response) = @_;

    if (not $response->is_success) {
	croak("Can't get URL: " . $response->status_line);
    }
    
    if ($response->content =~ m/Fatal system error/i) {
	croak("Application returned an error");
    }
}

=pod
sub fetch_watches {
    my (%args) = @_;
    %args{'mode'} = 'watches';
    return fetch_watchers(%args);
}
=cut

sub fetch_watchers {
    my (%args) = @_;
    $args{'user'} || croak("Required parameter 'user' undefined.");
    $args{'uid'}  || croak("Required parameter 'uid' undefined.");
    $args{'mode'} |= 'watched_by';

    my $url;
    my $buddies_raw = '';
    my $page = 1;
    while ($page > 0) {
	# Fetch buddy list page
	$url = "http://www.furaffinity.net/budslist/?name=$args{'user'}&uid=$args{'uid'}&page=$page&mode=$args{'mode'}";
	open(LINKS, "/usr/bin/links -dump '$url' 2>&1 |") || croak("Error while running links");
	my $result = '';
	while (<LINKS>) {
	    $_ =~ s/^[ \t]*//;
	    if (/^[~@!]/) {
		$result .= $_;
	    }
	}
	close(LINKS);

	#warn $result;

	if ($result ne '') {
	    $buddies_raw .= $result;
	    $page++;
	} else {
	    $page = 0; #BREAK
	}

	if ($page >= 25) {
	    $page = 0;
	}
    }

    print $buddies_raw;

}

