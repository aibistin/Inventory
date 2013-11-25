# ABSTRACT: Handy Date Utilities
#===============================================================================
#
#         FILE: MyDateUtil.pm
#
#  DESCRIPTION: Utility functions Relating to Dates and Time
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Austin Kenny (), aibistin.cionnaith@gmail.com
# ORGANIZATION: Carry On Coding
#      VERSION: 1.0
#      CREATED: 10/09/2013 08:38:00 PM
#     REVISION: ---
#===============================================================================
#-------------------------------------------------------------------------------
#  Exports handy date functions
#-------------------------------------------------------------------------------
package MyDateUtil;
use Modern::Perl;
use autodie;
use Carp 'croak';
use Exporter::NoWork;
use Data::Dump qw/dump/;
# use DateTime::Tiny;
use DateTime::Format::DBI;
use Try::Tiny;

#-------------------------------------------------------------------------------
#  "Constants"
#-------------------------------------------------------------------------------
use MyConstant qw/$YES $NO $FAIL $EMPTY_STR  $SPACE $COMMA $DOT $COLON $EMPTY
  $F_SLASH $B_SLASH $DASH $TRUE $FALSE/;
use MyDateConstant qw/
  $YEAR_RX
  $MONTH_RX
  $DAY_RX
  $DATE_SEPERATOR
  $YYYY_MM_DD_REGEX
  $MM_DD_YYYY_REGEX
  $DD_MM_YYYY_REGEX
  $HOUR_RX
  $MINUTE_RX
  $SECOND_RX
  $MAYBE_AM_OR_PM_Rx
  $TIME_SEPERATOR
  $MAYBE_SPACE_RX
  $MAYBE_T_RX
  $MAYBE_SPACE_OR_T_RX
  $MM_DD_YYYY_HH_MM_SS_AMPM
  $HH_MM_SS_AMPM
  $YYYY_MM_DDTHHMMSS/;

#-------------------------------------------------------------------------------
#  Convertors
#-------------------------------------------------------------------------------
my %month_to_number = (
    january   => 1,
    february  => 2,
    march     => 3,
    april     => 4,
    may       => 5,
    june      => 6,
    july      => 7,
    august    => 8,
    september => 9,
    october   => 10,
    november  => 11,
    december  => 12
);
my %mon_to_number = (
    jan => 1,
    feb => 2,
    mar => 3,
    apr => 4,
    may => 5,
    jun => 6,
    jul => 7,
    aug => 8,
    sep => 9,
    oct => 10,
    nov => 11,
    dec => 12
);

my %number_to_month = (
    1  => 'january',
    2  => 'february',
    3  => 'march',
    4  => 'april',
    5  => 'may',
    6  => 'june',
    7  => 'july',
    8  => 'august',
    9  => 'september',
    10 => 'october',
    11 => 'november',
    12 => 'december'
);

my %number_to_mon = (
    1  => 'jan',
    2  => 'feb',
    3  => 'mar',
    4  => 'apr',
    5  => 'may',
    6  => 'jun',
    7  => 'jul',
    8  => 'aug',
    9  => 'sep',
    10 => 'oct',
    11 => 'nov',
    12 => 'dec'
);

#------ Note 00 and 24 are technically the same.
#   24 refers to the last minute of one day,  00 to first minute of next day
#   Which are the same.
my %from_24_hr_to_12 = (
    0  => 12,
    13 => 1,
    14 => 2,
    15 => 3,
    16 => 4,
    17 => 5,
    18 => 6,
    19 => 7,
    20 => 8,
    21 => 9,
    22 => 10,
    23 => 11,
    24 => 12
);

#-------------------------------------------------------------------------------
#                  METHODS
#-------------------------------------------------------------------------------

sub convert_yyyy_mm_dd_T_hhmmss_to_hash {
    my $date_time_str = shift;
    my %dt_h;
    if ( $date_time_str =~ $YYYY_MM_DDTHHMMSS ) {
        %dt_h = (
            year   => $+{year},
            month  => $+{month},
            day    => $+{day},
            hour   => $+{hour},
            minute => $+{minute},
            second => $+{second},
        );
    }
    return \%dt_h;
}

#------ Format To

=head2 format_yyyy_mm_dd_T_hhmmss 
       Converts a date hash to something like this: Oct 2'nd 2013, 2:35 AM 
=cut

sub format_yyyy_mm_dd_T_hhmmss {
    return $FAIL unless $_[0];
    my $dt_h = convert_yyyy_mm_dd_T_hhmmss_to_hash(shift);
    my $mon  = ucfirst( convert_number_to_mon( $dt_h->{month} ) );
    ( my $hr_str, my $am_pm ) = convert_from_24_hr_to_12( $dt_h->{hour} );
    my $day       = add_suffix_to_day( $dt_h->{day} + 0 );
    my $pretty_dt = $mon

      #      . $COMMA
      . $SPACE . $day . $SPACE

      #      . $dt_h->{year} . ' at '
      . $dt_h->{year}
      . $COMMA
      . $SPACE
      . $hr_str
      . $COLON
      . $dt_h->{minute}
      . $SPACE
      . $am_pm;
    return $pretty_dt;
}

=head2 localtime_iso_format
   Get Formatted Local time from this format : Tue Oct 22 21:34:50 2013
                            To this format  :  2013-10-19T22:29:56
=cut

sub localtime_to_iso_format {

    # #  0        1        2         3         4       5          6
    (
        my $sec, my $min, my $hour, my $mday, my $mon, my $year, my $wday,
        my

          #  7         8
          $yday, my $isdst
    ) = localtime(time);

    return
        ( $year + 1900 ) . '-'
      . ( $mon + 1 ) . '-'
      . $mday . 'T'
      . $hour . ':'
      . $min . ':'
      . $sec;
}

=head2 get_db_formatted_localtime
   Get Formatted Local time for the current DataBase. 
   Pass a DBI database handle. Returns the Current Date Time
   formatted for that Data Base.
=cut

sub get_db_formatted_localtime {
    my $dbh = shift or croak('get_db_formatted_localtime() requires a DBH!');
    my $db_parser = DateTime::Format::DBI->new($dbh);
    my $dt        = try {
        require DateTime;
        DateTime->now();
    };
    return $FAIL unless $dt;
    return $db_parser->format_datetime($dt);
}

=head2 convert_number_to_month
   Converts a number (1, 12) to a month string
   Pass 1,  Returns january
=cut

sub convert_number_to_month {
    my $num = shift;
    return ( $number_to_month{ $num + 0 } || $FAIL );
}

=head convert_number_to_mon
   Converts a number (1, 12) to an abbreviated month string
   Pass 1,  Returns jan
=cut

sub convert_number_to_mon {
    my $num = shift // 0;
    return ( $number_to_mon{ $num + 0 } || $FAIL );
}

sub convert_number_to_mth {

    #---Just in case
    return convert_number_to_mon(shift);
}

=head convert_month_to_number
   Converts a month (january...december) to its corresponding month number.
   Pass July(july),  Returns 7
=cut

sub convert_month_to_number {
    my $month = shift;
    return ( $month_to_number{ lc $month } || $FAIL );
}

=head convert_mon_to_number
   Converts an abbreviated month (jan...dec) to its corresponding month number.
   Pass Aug(aug or aUg),  Returns 8
=cut

sub convert_mon_to_number {
    my $mon = shift;
    return ( $mon_to_number{ lc $mon } || $FAIL );
}

sub convert_mth_to_number {

    #--- Just in case
    return convert_mon_to_number(shift);
}

=head convert_from_24_hr_to_12
   Converts a Number representing an Hour (1 .. 24) to its 12hr clock format.
   Pass 1,  Returns (1, 'AM')
   Pass 14,  Returns (2, 'PM')
=cut

sub convert_from_24_hr_to_12 {
    my $hour = shift;
    $hour += 0;
    return ( $hour, q/AM/ ) if ( ( $hour >= 1 ) && ( $hour <= 12 ) );
    if ( ( $hour > 12 ) && ( $hour <= 24 ) ) {
        return ( $from_24_hr_to_12{$hour}, q/PM/ );
    }
    return $FAIL;
}

=head2 add_suffix_to_day
       Good for printing dates.
       Given an integer; Returns a string of the number with a
       suitable Suffix appended to it.
       Given 21; Returns "21'st"
             33;         "33'rd" etc.
=cut

sub add_suffix_to_day {
    my $num = shift;
    croak 'add_suffix_to_day() needs a day number!' unless $num;
    if ( $num =~ /(?<!1)1$/ ) {
        $num .= '\'st';
    }
    elsif ( $num =~ /(?<!1)2$/ ) {
        $num .= '\'nd';
    }
    elsif ( $num =~ /(?<!1)3$/ ) {
        $num .= '\'rd';
    }
    else {
        $num .= '\'th';
    }
    return $num;
}

#-------------------------------------------------------------------------------
1;

