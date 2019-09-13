#! /usr/bin/perl
use warnings;
use strict;

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

my %oldname_newname = ();
open my $file_fh, "<", "$file1" or die "can't open file '$file1'! $!";
while (<$file_fh>) {
    chomp $_;
    my @one_line = (split(/\t/,$_));
    $oldname_newname{$one_line[0]}=$one_line[1];
}
close $file_fh;

open my $file_fh2, "<", "$file2";
while (<$file_fh2>) {
    chomp $_;
    my @one_line = (split("\t",$_));
    my $one_line_maxindex = $#one_line;
    my $outline = $oldname_newname{$one_line[0]};
    for (my $i = 1;$i <= $one_line_maxindex; $i++) {
        $outline .= "\t$one_line[$i]";
    }
    print "$outline\n";
}
close $file_fh2;
