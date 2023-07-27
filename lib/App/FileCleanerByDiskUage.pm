package App::FileCleanerByDiskUage;

use 5.006;
use strict;
use warnings;

=head1 NAME

App::FileCleanerByDiskUage - 

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use App::FileCleanerByDiskUage;

    my $removed=App::FileCleanerByDiskUage->clean(path=>'/var/log/suricata/pcap/', ignore=>'\.pcap$', du=>90);

=head1 Functions

=head2 clean

=cut

sub clean {
	my ( $empty, %opts ) = @_;

	if ( !defined( $opts{path} ) ) {
		die('$opts{path} is not defined');
	} elsif ( !-d $opts{path} ) {
		die( '$opts{path} is set to "' . $opts{path} . '" which is not a directory or does not exist' );
	}

	if ( !defined( $opts{du} ) ) {
		die('$opts{du} is not defined');
	} elsif ( $opts{du} !~ /^\d+$/ ) {
		die( '$opts{du} is set to "' . $opts{du} . '" whish is not numeric' );
	}

	my $results = { deleted => [], errors => [] };

	my $df = df( $opts{path} );

	if ( $df->{per} < $opts{du} ) {
		return $results;
	}

	my @files;
	if ( defined( $opts{ignore} ) ) {
		my $ignore_rule = File::Find::Rule->new;
		$ignore_rule->name(qr/$opts{ignore}/);
		@files = File::Find::Rule->file()->not($ignore_rule)->in( $opts{path} );
	} else {
		@files = File::Find::Rule->file()->in( $opts{path} );
	}

	my @files_info;
	foreach my $file (@files) {
		my %file_info;
		(
			$file_info{dev},   $file_info{ino},     $file_info{mode}, $file_info{nlink}, $file_info{uid},
			$file_info{gid},   $file_info{rdev},    $file_info{size}, $file_info{atime}, $file_info{mtime},
			$file_info{ctime}, $file_info{blksize}, $file_info{blocks}
		) = stat($file);
		$file_info{name} = $file;
		push( @files_info, \%file_info );
	} ## end foreach my $file (@files)

	@files_info = sort { $a->{mtime} cmp $b->{mtime} } @files_info;

	my $int = 0;
	while ( $df->{per} >= $opts{du} && defined( $files_info[$int] ) ) {
		eval { unlink( $files_info[$int]{name} ) or die($!); };
		if ($@) {
			push( @{ $results->{errors} }, 'Failed to remove "' . $files_info[$int]{name} . '"... ' . $@ );
		}

		$int++;
		$df = df( $opts{path} );
	}

	return $results;
} ## end sub clean

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-filecleanerbydiskuage at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-FileCleanerByDiskUage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::FileCleanerByDiskUage


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-FileCleanerByDiskUage>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-FileCleanerByDiskUage>

=item * Search CPAN

L<https://metacpan.org/release/App-FileCleanerByDiskUage>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 3, June 2007


=cut

1;    # End of App::FileCleanerByDiskUage
