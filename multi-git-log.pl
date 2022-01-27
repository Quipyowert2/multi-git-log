#!/usr/bin/perl
use strict;
use warnings;
#use File::Find;
use Git;
use Getopt::Long;
use Pod::Usage;
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
sub date {
    my ($commit) = @_;
    if ($commit !~ m/Date:\s*([^\n]+)/) {
        print STDERR "No date found in commit $commit";
        return;
    }
    return $1;
}
# --author, --committer from `git log`
my ($author, $committer);
my ($help, $man) = 0;
my $patch = 0;
GetOptions("author=s" => \$author,
           "committer=s" => \$committer,
           "help|?" => \$help,
           "man" => \$man,
           "patch|p" => \$patch);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;
if (!scalar @ARGV) {
    print "Please specify a directory to search for git repositories.\n";
    pod2usage(1);
}
my @gitdirs;
foreach my $dir (@ARGV) {
   foreach my $glob (glob("$dir/.git"), glob "$dir/*/.git") {
       next unless -e $glob; #Only process existing .git directories
       $glob =~ s/.git$//;
       push @gitdirs, $glob;
   }
}
my @allcommits = ();
foreach my $repodir (@gitdirs) {
    print STDERR "Repository: $repodir\n";
    my $repo = Git->repository(Directory => $repodir);
    my @cmdline = ('log', '--date=iso');
    if (defined $author) {
        push @cmdline, "--author=$author";
    }
    if (defined $committer) {
        push @cmdline, "--committer=$committer";
    }
    if ($patch) {
        push @cmdline, "-p";
    }
    print STDERR "\@cmdline=@cmdline\n";
    my @commits;
    eval {
        @commits = parseCommits($repo->command(@cmdline));
        1;
    } or next;
    if (scalar @commits == 1 and not defined $commits[0]) {
        # parseCommits returned undef.
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
        push @allcommits, @commits;
    }
}
#Schwartzian sort aka decorate sort undecorate
print map {$_->[0]} sort {$b->[1] cmp $a->[1]} map {[$_, date($_)]} @allcommits;
__END__

=head1 NAME

multi-git-log.pl - View your git commits across multiple repositories

=head1 SYNOPSIS

multi-git-log.pl --author="Your name" ~/src

=head1 OPTIONS

=over 8

=item B<--author>
Shows commits authored by a certain author.

=item B<--committer>
Shows commits whose committer field matches the following argument.

=item B<--patch>
Show diff of each commit

=item B<--help>

Outputs usage message.

=item B<--man>

Prints this pod document.

=back

=head1 DESCRIPTION

This program shows your (or someone else's) commits in multiple repositories. The --author and --committer options tell the program which commits to show. Multiple directories can be specified.

=cut
