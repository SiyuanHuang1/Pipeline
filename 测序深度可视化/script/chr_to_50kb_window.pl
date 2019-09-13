#! /usr/bin/perl
use warnings;
use strict;

my $parm_name = $ARGV[0];
open my $file_fh, "<", "$parm_name";
open my $file_fh2, ">", "chr_to_50kb.bed";

while (<$file_fh>) {
	chomp $_;
	my @one_line = (split("\t", $_));
	my $num = int($one_line[2]/50000);
	for(my $i=1; $i <= $num; $i++) {
		my $left = 50000*($i-1);
		my $right = 50000*($i);
		print $file_fh2 "$one_line[0]\t$left\t$right\n";
	}
	my $left2 = $num*50000;
	my $right2 = $one_line[2];
	print $file_fh2 "$one_line[0]\t$left2\t$right2\n";
}
close $file_fh;
close $file_fh2;
