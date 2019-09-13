#! /usr/bin/perl
use warnings;
use strict;

my %chuangkou_weizhi=();
open my $file_fh1, "<", "tmp4";
while (<$file_fh1>) {
    chomp $_;
    my @one_line=(split("\t",$_));
    $chuangkou_weizhi{$one_line[0]}=$one_line[1];
}
close $file_fh1;

open my $file_fh2, "<", "tmp3";
open my $file_fh3, ">", "tmp5";
while (<$file_fh2>) {
    chomp $_;
    my @one_line = (split("\t",$_));
    my $chuangkou = $one_line[0]."-".$one_line[1];
    print $file_fh3 "$one_line[0]\t$one_line[1]\t$chuangkou_weizhi{$chuangkou}\t$one_line[2]\n";
}
close $file_fh3;
