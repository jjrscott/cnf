use DirHandle;

sub search
{
	my ($block, @path) = @_;
	my $path = join '/', @path;
	if ($block->(@path) && -d $path)
	{
		my $handle = DirHandle->new($path) || return;
		my @files = $handle->read();
		$handle->close();
		foreach my $file (@files)
		{
			next if $file =~ /^\.{1,2}$/;
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

return 1;