package PAPS::Refs::Importer;

use 5.006;
use strict;
use warnings FATAL => 'all';
use PAPS::Database::papsdb::Schema;

=head1 NAME

PAPS::Refs::Importer - The great new PAPS::Refs::Importer!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

# get the input file name as the first argument.
# die if it is not provided or the file does not exist.
my $input_file_name = shift @ARGV;
die "$0: Must provide an input file name as an argument.\n" unless $input_file_name;
die "$0: Input file '${input_file_name}' does not exist.\n" unless -e $input_file_name;

my $schema = PAPS::Database::papsdb::Schema->connect('dbi:Pg:dbname=papsdb',
                                                     'papsuser', '');

# Get the user's id value.  Die if it cannot be found.
my $user_name = 'RefImporter';
my $user = $schema->resultset('User')->find( { 'me.name' => $user_name }, undef );
die "$0: Error: User '${user_name}' not found.  Quitting.\n" unless $user;
my $user_id = $user->id;

# Get the algorithm's id value.  Die if it cannot be found.
my $algorithm_name = 'Simple Text Import';
my $algorithm = $schema->resultset('Algorithm')->find( { 'me.name' => $algorithm_name }, undef );
die "$0: Error: Id for algorithm '${algorithm_name}' not found.  Quitting.\n" unless $algorithm;
my $algorithm_id = $algorithm->id;

# Get the persona's id value.  Die if it cannot be found.
my $persona = $schema->resultset('Persona')->find(
                                                  {
                                                   'me.user_id' => $user_id,
                                                   'me.algorithm_id' => $algorithm_id,
                                                   'me.version' => $VERSION,
                                                  }, undef );
die "$0: Error: Id for persona for user id ${user_id}, algorithm id ${algorithm_id}, and version $VERSION not found.  Quitting.\n" unless $persona;
my $persona_id = $persona->id;

my $refs = [ ];
my $current_ref = "";

my $fh;
my $mode = "settings";
my $work_id;
my $references_chapter;
my $references_location;
open($fh, "<", $input_file_name) or die "$0: Cannot open input file '${input_file_name}' for reading: $!\n";
while (my $line = <$fh>) {
  chomp $line;

  if ($mode eq "settings") {
    if ($line =~ /^\s*$/) {
      $mode = "input";
      next;
    }

    my ($key, $value) = $line =~ /^\s*(.*?)\s*=\s*(.*?)\s*$/;

    unless ($value) {
      print "Settings line is not properly formatted: $line\n";
      next;
    }

    if ($key eq "work") {
      $work_id = $value;
      print "Using work id '${work_id}'.\n";
    }
    elsif ($key eq "chapter") {
      $references_chapter = $value;
      print "Using reference chapter '${references_chapter}'.\n";
    }
    elsif ($key eq "location") {
      $references_location = $value;
      print "Using reference location '${references_location}'.\n";
    }
    else {
      print "Found unexpected key '${key}' with value '${value}'.\n";
    }
  }
  elsif ($mode eq "input") {
    #print "found input '$line'\n";

    if ($line =~ /^\s*$/) {
      # end of current refernce
      #print "Adding reference '${current_ref}' to references list.\n";
      push $refs, $current_ref unless $current_ref =~ /^\s*$/;
      $current_ref = "";
    }
    else {
      $current_ref = $current_ref . $line;
    }
  }
  else {
    print "In unknown mode '${mode}'.\n";
    last;
  }
}

# TODO:
# - open input file (done)
# - read in settings
#   - lines with key/value pair (done)
#   - id of work to add references to (done)
#   - section from where ids are from (reference type) (done)
#   - (later) replace or update existing references
#   - (later) option to remove newlines in reference text
# - stop parsing settings at first blank line (done)
# - read in references (done)
#   - each reference  is separated by a blank line (to allow embedded newlines) (done)
# - insert each parsed reference into an array (done)
# - use DBIx to update or insert each reference parsed
#   - assume references start at rank 1 and increment each time
#   - (later) method to skip reference.  possibly by making input file tab-delimited.
# - log messages to output with result of parsing and actions
# - DB changes
#   - have some way to store who is adding the references
#     - like how referenced work guesses are recorded


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use PAPS::Refs::Importer;

    my $foo = PAPS::Refs::Importer->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Charles Macanka, C<< <cmacanka at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-paps-refs-importer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PAPS-Refs-Importer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAPS::Refs::Importer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PAPS-Refs-Importer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PAPS-Refs-Importer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAPS-Refs-Importer>

=item * Search CPAN

L<http://search.cpan.org/dist/PAPS-Refs-Importer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Charles Macanka.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PAPS::Refs::Importer
