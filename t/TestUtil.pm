# ABSTRACT: Handy Module for some common test functions
#-------------------------------------------------------------------------------
#  Author: Austin Kenny
#-------------------------------------------------------------------------------
package TestUtil;
use Modern::Perl;
use List::Util qw/sum/;
use List::MoreUtils qw/all any/;
use Scalar::Util qw/reftype blessed/;
use Carp qw /confess/;
use POSIX;
use Test::More;
use Test::Exception;

#--- To export functions
use Exporter::NoWork;

#-------------------------------------------------------------------------------
#  Constants
#-------------------------------------------------------------------------------
my $TRUE      = 1;
my $FALSE     = 0;
my $FAIL      = undef;
my $EMPTY_STR = q//;
my $EMPTY     = q/<empty>/;

#-------------------------------------------------------------------------------
#  Functions
#-------------------------------------------------------------------------------
=head2 is_attr
    Pass: attribute name, 'got' attribute value, 'expected' attribute value, 
          attribute defaults, and an optional message prelude.

    Tests the 'got' value against the 'expected' value or 'default' value
    using the TestMore 'is' function.
=cut
sub is_attr {
    my $attr_name       = shift;
    my $got_attr_val    = shift;
    my $expect_attr_val = shift;
    my $attr_defaults   = shift
      // confess 'You forgot to send the DEFAULT attributes!!';
    my $message = shift || $EMPTY_STR;

    #--- If the Objects attr matches the Expected  result
    #    or if The Object attr will not match the Default ( bad attr)
    if (   ( $got_attr_val eq $expect_attr_val )
        or ( $got_attr_val ne $attr_defaults->{$attr_name} ) )
    {
        $message .=
            'Attribute '
          . $attr_name
          . ', has correct value : '
          . ( $expect_attr_val // $EMPTY_STR );

        is( $got_attr_val, $expect_attr_val, $message );
        return;
    }

    #--- If the Objects attr is not eq the the expected attr, then try the
    #    Default value
    $message .=
        'Attribute '
      . $attr_name
      . ' matches Default value: '
      . ( $attr_defaults->{$attr_name} // $EMPTY_STR );

    is( $got_attr_val, $attr_defaults->{$attr_name}, $message )

}

#-------------------------------------------------------------------------------
#  Pass actual result,  ArayRef of expected results and test name.
#-------------------------------------------------------------------------------
=head2 is_any
   Pass: A 'got' value and test it against an arrray of expected results. 
         An array of expected values.
         An optional message.
   Uses the 'ok' function to give a good result if the 'got' value is 
   equal to any of the Expected Array values.
=cut

sub is_any {

    my ( $actual, $expected, $name ) = @_;

    $name ||= '';

    ok( ( any { $_ eq $actual } @$expected ), $name )

      or diag "Received: $actual\nExpected:\n" .

      join "", map { "         $_\n" } @$expected;

}

#-------------------------------------------------------------------------------
1;
__END__
