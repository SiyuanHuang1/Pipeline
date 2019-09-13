#! /usr/bin/perl
use warnings;
use strict;

my %chuangkou_jianji=();
open my $file_fh, "<", "tmp1";
while (<$file_fh>) {
    chomp $_;
    my @one_line = (split("\t",$_));
    if (exists $chuangkou_jianji{$one_line[0]}) {
        $chuangkou_jianji{$one_line[0]} = $chuangkou_jianji{$one_line[0]} + $one_line[1];
    } else {
        $chuangkou_jianji{$one_line[0]} = $one_line[1];
    }
}
close $file_fh;

open my $file_fh2, ">", "tmp2";
foreach my $i ( sort keys %chuangkou_jianji) {
    print $file_fh2 "$i\t$chuangkou_jianji{$i}\n";
}
close $file_fh2;
