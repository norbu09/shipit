package ShipIt::Step::UploadPuppet;
use strict;
use base 'ShipIt::Step';
use ShipIt::Util qw(bool_prompt in_dir);
use File::Copy ();

sub init {
    my ($self, $conf) = @_;
    $self->{dir} = $conf->value("puppet.dir");
    die "puppet.dir not defined in config."     unless $self->{dir};
    die "puppet.dir's value isn't a directory." unless -d $self->{dir};
    $self->{file} = $conf->value("puppet.file");
}

sub run {
    my ($self, $state) = @_;
    my $distfile =  $state->distfile;
    die "No distfile was created!"             unless $distfile;
    die "distfile $distfile no longer exists!" unless -e $distfile;

    if ($state->dry_run) {
        warn "*** DRY RUN, not committing to Puppet!\n";
        return;
    }

    return unless bool_prompt("Commit to Puppet?", "y");
    File::Copy::copy($distfile, $self->{dir}.'/'.$self->{file}) or
        die "file copy of $distfile to $self->{dir} failed: $!\n";

    in_dir($self->{dir}, sub {
        system("git", "add", $self->{file}) and die "git add failed";
        system("git", "commit", "-m", "auto-adding $self->{file} using shipit") and die "git commit failed";
        system("git", "push") and die "git push failed";
    });
}

1;
