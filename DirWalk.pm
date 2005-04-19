# Copyright (c) 2005 Jens Luedicke. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package File::DirWalk;

our $VERSION = '0.1';

use strict;
use warnings;

use File::Basename;

use constant FAILED => 0;
use constant SUCCESS => 1;
use constant ABORTED => -1;

sub new {
	my ($class) = @_;
	my $self = bless {}, $class;

	foreach (qw(onBeginWalk onLink onFile onDirEnter onDirLeave onForEach)) {
		$self->{$_} = sub { SUCCESS; };
	}

	return $self;
}

sub onBeginWalk {
	my ($self,$func) = @_;
	$self->{onBeginWalk} = $func;
}

sub onLink {
	my ($self,$func) = @_;
	$self->{onLink} = $func;
}

sub onFile {
	my ($self,$func) = @_;
	$self->{onFile} = $func;
}

sub onDirEnter {
	my ($self,$func) = @_;
	$self->{onDirEnter} = $func;
}

sub onDirLeave {
	my ($self,$func) = @_;
	$self->{onDirLeave} = $func;
}

sub onForEach {
	my ($self,$func) = @_;
	$self->{onForEach} = $func;
}

sub walk {
	my ($self,$path) = @_;

	if ((my $r = &{$self->{onBeginWalk}}($path)) != SUCCESS) {
		return $r;
	}

	if (-l $path) {

		if ((my $r = &{$self->{onLink}}($path)) != SUCCESS) {
			return $r;
		}

	} elsif (-d $path) {

		if ((my $r = &{$self->{onDirEnter}}($path)) != SUCCESS) {
			return $r;
		}

		opendir(DIR, $path) || return FAILED;

		foreach my $f (readdir(DIR)) {
			next if ($f eq "." or $f eq "..");

			if ((my $r = &{$self->{onForEach}}("$path/$f")) != SUCCESS) {
				return $r;
			}

			if ((my $r = $self->walk("$path/$f")) != SUCCESS) {
				return $r;
			}
		}

		closedir(DIR);

		if ((my $r = &{$self->{onDirLeave}}($path)) != SUCCESS) {
			return $r;
		}
	} else {
		if ((my $r = &{$self->{onFile}}($path)) != SUCCESS) {
			return $r;
		}
	}

	return SUCCESS;
}

1;

=head1 NAME

File::DirWalk - walk through a directory tree and run own code

=head1 SYNOPSIS

Walk through your homedir and print out all filenames. 

	use File::DirWalk;
	
	my $dw = new File::DirWalk;
	$dw->onFile(sub {
		print $_[0], "\n";
		return File::DirWalk::SUCCESS;
	});

	$dw->walk($ENV{'HOME'});

=head1 DESCRIPTION

This module can be used to walk through a directory tree and run own functions
on files, directories and symlinks.

=head1 METHODS

=over 4

=item C<new()>

Create a new File::DirWalk object

=item C<onBeginWalk(\&func)>

=item C<onLink(\&func)>

=item C<onFile(\&func)>

=item C<onDirEnter(\&func)>

=item C<onDirLeave(\&func)>

=item C<onForEach(\&func)>

All methods expect a function reference as their callbacks. The function must
return true, otherwise the recursive walk is aborted and C<walk> returns.
You don't need to define a callback if you don't need to. 

=item C<walk($path)>

Begin the walk through the given directory tree. This module returns if the walk
is finished or if one of the callbacks doesn't return true.

=back

The module provides the following constants SUCCESS, FAILED and ABORTED (1, 0 and -1)
which you can use within your callback code. 

=head1 BUGS

Please mail the author if you encounter any bugs.

=head1 AUTHOR

Jens Luedicke E<lt>jensl@cpan.orgE<gt>

Copyright (c) 2005 Jens Luedicke. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
