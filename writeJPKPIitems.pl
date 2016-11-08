#!/usr/bin/perl

##-----------------------------------------------------------------------
##
## 2016/11/08 
## Ryoichi Naito, ryoichi.naito@thomsonreuters.com
##
## To gather all available KPI items for Japanese stocks that are listed in EstPermID.list.
## You need to set up your ODBC (as 'qad') on your PC before running this script.
##
##-----------------------------------------------------------------------

#use warnings;
use strict;
use DBI;

# File settings
my $listFile = "./EstPermID.list";
my $outFile = "./Result.csv";

# DB settings
print "Please type your DB user name:\n";
my $stdinUser=<STDIN>;
chomp($stdinUser);
print "Please type your DB password:\n";
my $stdinPw=<STDIN>;
chomp($stdinPw);

my $dataSource = 'dbi:ODBC:qad';
my $dbh = DBI->connect($dataSource, $stdinUser, $stdinPw) or die "Can't connect to $dataSource: $DBI::errstr";


open(LIST, "<$listFile");

while(<LIST>) {
    chomp;
    my $curEstID = $_;

    my $sql = 'select top 2 * from GSecMstrX';
    my $sth = $dbh->prepare($sql) or die "Can't prepare statement: $DBI::errstr";
    $sth->execute();

    # Print the column name.
    print "$sth->{NAME}->[0]\n";

    # Fetch and display the result set value.
    while( my @row = $sth->fetchrow_array ) {
        print join(',', @row), "\n";
    }
    $sth->close();
    $dbh->disconnect;

}

close(LIST);
exit(0);


