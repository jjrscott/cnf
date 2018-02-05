#!/usr/bin/perl -CS

# This script builds an archive release of a project. It should be run thus:
# $ cd <the project directory>
# $ build_scheme

use strict;
use Getopt::Long;
use File::Temp qw(tempdir);
use Digest::MD5 qw(md5 md5_hex md5_base64);
use JSON::PP;

GetOptions
(
);

# $ENV{'C_INCLUDE_PATH'} = qx(pwd);


foreach my $path (@ARGV)
{
	search(\&handle_file, $path);
}



sub handle_file
{
	my $path = join "/", @_;
	if ($path =~ /\.c$/)
	{
		die $path if system "clang", "-I.", "-Wno-everything", "-o", "/dev/null", $path;
	}
	return 1;
}

use DirHandle;

sub search
{
	my ($block, @path) = @_;
	my $handle = DirHandle->new(join '/', @path) || return;
	my @files = $handle->read();
	$handle->close();
	foreach my $file (@files)
	{
		next if $file =~ /^\.{1,2}$/;
		if ($block->(@path, $file) && -d join '/', @path, $file)
		{
			search($block, @path, $file);
		}
	}
}

sub read_file
{
	my ($encoding, $path) = @_;
	open(my($file), '<:encoding('.$encoding.')', $path) || die "read_file $!: $path\n";
	my $content = "";
	while(<$file>) {
		$content .= $_;
	}
	close $file;
	return $content;
}

sub write_file
{
	my ($encoding, $path, $content) = @_;
	if (defined $content)
	{
		my $parent = $path;
		$parent =~ s!/[^/]+$!!;
		if (!-e $parent)
		{
			system "mkdir", "-p", $parent;
		}
		if (!-e $path || read_file($encoding, $path) ne $content)
		{
			open(my($file), '>:encoding('.$encoding.')', $path) || die "write_file $!: $path\n";
			print $file $content;
			close $file;
		}
	}
	elsif (-e $path)
	{
		system "rm", "-f", $path;
	}
}

BEGIN
{
	my $json = JSON::PP->new->canonical(1)->pretty(1)->relaxed(1)->allow_nonref();

	sub Dumper
	{
		if (@_ > 1)
		{
			return $json->encode(\@_);
		}
		else
		{
			return $json->encode($_[0]);
		}
	}
}