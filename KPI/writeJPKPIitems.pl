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

use warnings;
use strict;
use DBI;

# File settings
my $listFile = "./EstPermID.list";
my $outFile = "./Result1.csv";

# DB settings
print "Please type your DB user name:\n";
my $stdinUser=<STDIN>;
chomp($stdinUser);
print "Please type your DB password:\n";
my $stdinPw=<STDIN>;
chomp($stdinPw);
my $dbh = DBI->connect('dbi:ODBC:qad', $stdinUser, $stdinPw) or die $!;

# Read EstPermID list.
print "Opening $listFile(READ) and $outFile(WRITE) before executing queries.\n";
open(LIST, "<$listFile");
open(OUT, ">$outFile");

while(<LIST>) {
    chomp;
    my $curEstID = $_;

#--------------------------------- SQL
    my $sql = <<"EOD";
select
	tsum.EstPermID
,	tsum.Measure
,	mcod.Description
,	Min(tsum.PerEndDate) as 'PerEndDate'
,	tsum.DefMeanEst
from
	TRESumPer tsum
	join TRECode mcod on tsum.Measure = mcod.Code and mcod.CodeType=5
where
	tsum.EstPermID= $curEstID
	and tsum.ExpireDate is null
	and tsum.PerEndDate > GetDate()
group by
	tsum.EstPermID, tsum.Measure, mcod.Description, tsum.DefMeanEst
EOD
#-------------------------------------
    print $sql;

    my $sth = $dbh->prepare($sql) or die $dbh->errstr;

    # Avoid error outputs and execute
    $sth->{LongTruncOk}=1;
    $sth->{LongReadLen}=2000000;
    $sth->execute() or die $dbh->errstr;

    # Fetch and display the result set value.
    my $count = 0;
    my $lastID = '';
    my $lastItem = '';
    while( my @row = $sth->fetchrow_array ) {
        if($count == 0) {
            print join(',', @row), "\n";
            print OUT join(',', @row), "\n";
            $lastID = $row[0];
            $lastItem = $row[1];
        }
        elsif($lastID ne $row[0] && $lastItem ne $row[1]) {
            print join(',', @row), "\n";
            print OUT join(',', @row), "\n";
            $lastID = $row[0];
            $lastItem = $row[1];
        }
        else {
            $lastID = $row[0];
            $lastItem = $row[1];
        }
    }
}

close(LIST);
exit(0);


