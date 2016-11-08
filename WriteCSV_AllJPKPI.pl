#!/usr/bin/perl

##-----------------------------------------------------------------------
##
## 2016/11/08 
## Ryoichi Naito, ryoichi.naito@thomsonreuters.com
##
## To gather all available KPI items for Japanese stocks that are listed in EstPermID.list.
##
##-----------------------------------------------------------------------

use warnings;
use strict;

my $listFile = "./EstPermID.list";
my $outFile = "./Result.csv";

open(LIST, "<$listFile");
while(<LIST>) {
    chomp;
    my @line = split(/\t/, $_); 
    my $curEstID = $_[0];
 
    AppendResultQuery($curEstID, $outFile);
}

close(LIST);
exit(0);


sub AppendResultQuery {
    my $id = $_[0];
    my $file = $_[1];
}


