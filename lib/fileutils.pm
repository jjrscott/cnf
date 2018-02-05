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
	open(my($file), '<:encoding('.$encoding.')', $path) || die "error $!: $path\n";
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
		if (!-e $path || read_file($encoding, $path) ne $content)
		{
			open(my($file), '>:encoding('.$encoding.')', $path) || die "error $!: $path\n";
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