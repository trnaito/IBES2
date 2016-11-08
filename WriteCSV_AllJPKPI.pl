#!/usr/bin/perl

##-----------------------------------------------------------------------
##
## 2016/11/08 
## Ryoichi Naito, ryoichi.naito@thomsonreuters.com
##
## To make a contenuous time-series data for TRMI. 
## Main objective is to enable users to back test with the archive data.
##
##-----------------------------------------------------------------------

use warnings;
use strict;
use DateTime;

my $datadir = "./";
opendir(DIR, $datadir);
my @FILES = readdir(DIR);
closedir(DIR);

foreach(@FILES) {
    if($_ =~ /txt|csv/i) {
        print "The file name is $_, correct? (Y/N)\n";
        my $line = <STDIN>;
        chomp($line);
        if($line eq 'Y') {
            my $file = $_;

            # split each file for News_Social, News, Social
            SplitFiles($file);

            # make time-series data for each file
            MakeTimeSeries($file);

            exit;
        } else {
        }
    }
} 

sub SplitFiles {
    # initial definitions
    my $file = $_[0];

    my $outfile_ns = "./$file"."ns.txt";
    my $outfile_so = "./$file"."so.txt";
    my $outfile_ne = "./$file"."ne.txt";

    open(IN, "<$file");
    open(IN_NS, ">$outfile_ns") or die $!;
    open(IN_SO, ">$outfile_so") or die $!;
    open(IN_NE, ">$outfile_ne") or die $!;

    while(<IN>) {
        chomp;
        my @line = split(/\t/, $_); 

        if($line[3] eq 'News_Social') {
            print IN_NS join(',', @line), "\n";
        } elsif($line[3] eq 'Social') {
            print IN_SO join(',', @line), "\n";
        } elsif($line[3] eq 'News') {
            print IN_NE join(',', @line), "\n";
        }
    }
    close(IN);
    close(IN_NS);
    close(IN_SO);
    close(IN_NE);
}


sub MakeTimeSeries {

    my $sourceFile = $_[0];

    # dataType=News_Social ---------------------
    # my $inFile = $sourceFile."ns.txt";
    my @allInFiles = ($sourceFile."ns.txt", $sourceFile."so.txt", $sourceFile."ne.txt");

    foreach my $curInFile (@allInFiles) {

        # Initialization for all variables.
        my $lineCount = 0;
        my $curWindowTimeStamp='';
        my $curWTS_yea='';
        my $curWTS_mon='';
        my $curWTS_day='';
        my $curWTS_hou='';
        my $curWTS_min='';
        my $lastDt='';
        my $lastDt1m='';
        my $curDt='';
        my $fId=''; # element 0
        my $fAssetCode=''; # element 1
        my $fDataType=''; # element 3
        my $fSystemVersion=''; # element 4
        my $curOutFile = $curInFile."out.txt";

        print "Opening $curInFile to read and $curOutFile to write out\n";
        open(TSIN, "<$curInFile");
        open(TSNS, ">$curOutFile") or die $!;

        while(<TSIN>) {
            chomp($_);
            my @dline = split(/,/, $_);

            $curWindowTimeStamp = $dline[2];
            $fId = $dline[0];
            $fAssetCode = $dline[1];
            $fDataType = $dline[3];
            $fSystemVersion = $dline[4];

            $curWTS_yea = substr($curWindowTimeStamp, 0, 4);
            $curWTS_mon = substr($curWindowTimeStamp, 5, 2);
            $curWTS_day = substr($curWindowTimeStamp, 8, 2);
            $curWTS_hou = substr($curWindowTimeStamp, 11, 2);
            $curWTS_min = substr($curWindowTimeStamp, 14, 2);

            # The first line with no header
            if($lineCount==0) {
                $lastDt = DateTime->new(year=>$curWTS_yea, month=>$curWTS_mon, day=>$curWTS_day,
                                        hour=>$curWTS_hou, minute=>$curWTS_min);
                # Stores necessary fields
                $lastDt1m = $lastDt->add(minutes=>1);
                print TSNS join(',', @dline), "\n";
            }

            # From line 2. Compare $curDt with $lastDt1m
            else {
                $curDt = DateTime->new(year=>$curWTS_yea, month=>$curWTS_mon, day=>$curWTS_day,
                                       hour=>$curWTS_hou, minute=>$curWTS_min);

                # Write out if minute diff is 1 
                if($curDt == $lastDt1m) {
                    print TSNS join(',', @dline), "\n";
                    $lastDt1m = $curDt->add(minutes=>1);
                }

                # Put additional lines with missing minutes data
                else {
                    my $diffMin = $curDt - $lastDt1m;
                    my $intDiffMin = $diffMin->minutes;
                
                    print "TimeStamp++ does not match. Adding $intDiffMin rows.\n";

                    for (my $i=0; $i < $intDiffMin; $i++) {
                        # Make a new TimeStamp with $curDt.
                        # FORMAT_id              = "mp:2016-01-01_00.14.00.News_Social.CMPNY_GRP.MPTRXJP225"
                        # FORMAT_windowTimestamp = "2016-01-01T00:10:00.000Z"
                        my $formatTStamp1 = $lastDt1m->strftime('%Y-%m-%d');
                        my $formatTStamp2 = $lastDt1m->strftime('%H.%M.%S');
                        my $formatTStamp3 = $lastDt1m->strftime('%H:%M:%S').'.000Z';
                        $fId = 'mp:'.$formatTStamp1.'_'.$formatTStamp2.'.'.$fDataType.'.'.'CMPNY_GRP.MPTRXJP225'; # <- might need to be amended
                        $curWindowTimeStamp = $formatTStamp1.'T'.$formatTStamp3;
                    
                        my @addition = ($fId, $fAssetCode, $curWindowTimeStamp, $fDataType, $fSystemVersion,'','','','','','','','','','','','','','','','','','','','','','','');
                        print TSNS join(',', @addition), "\n";
                        $lastDt1m = $lastDt1m->add(minutes=>1);
                    }
                    print TSNS join(',', @dline), "\n";
                    $lastDt1m = $curDt->add(minutes=>1);
                }
            }
            $lineCount++;
        }
        close(TSIN);
        close(TSNS);
    }
}
exit;

