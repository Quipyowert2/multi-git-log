#!/usr/bin/perl
use strict;
use warnings;
#use File::Find;
use Git;
use Getopt::Long;
use Data::Dumper;
sub parseCommits {
    my @commits;
    my $currentcommit;
    foreach my $line (@_) {
        if ($line =~ m/^commit/) {
            if (defined $currentcommit) {
	        push @commits, $currentcommit;
		$currentcommit = "";
	    }
	}
	$currentcommit .= "$line\n";
    }
    push @commits, $currentcommit;
    return @commits;
}
# --author, --committer from `git log`
my ($author, $committer);
GetOptions("author=s", \$author,
           "committer=s", \$committer);
my $dir = shift;
my @gitdirs = map {s/.git$//;$_} glob "$dir/*/.git";
#print "author=$author\n";
#print join "\n", @gitdirs;
#print "\n";
foreach my $repodir (@gitdirs) {
    print STDERR "Repository: $repodir\n";
    my $repo = Git->repository(Directory => $repodir);
    my @cmdline = 'log';
    if (defined $author) {
        push @cmdline, "--author=$author";
    }
    if (defined $committer) {
        push @cmdline, "--committer=$committer";
    }
    print STDERR "\@cmdline=@cmdline\n";
    my @commits;
    eval {
        @commits = parseCommits($repo->command(@cmdline));
	1;
    } or next;
    if (scalar @commits == 1 and not defined $commits[0]) {
	my $who = "";
	if (defined $author) {
            $who .= "author=$author";
	}
	if (defined $committer) {
	    $who .= "committer=$committer";
	}
        print STDERR "No commits found for $who\n";
    }
    else {
	#print STDERR Dumper \@commits;
	print @commits;
    }
}
