use strict;

use utf8;
our $annotateStructure;
our $logParsing;
our %colors;
our $wrappingColor;
our %times;
our %counts;
our %stripSymbols;


sub log_parse
{
	return unless $logParsing;
	my ($message, $content, $depth) = @_;
	
	my $contentLength = length $content;
	
	$content = substr $content, 0, 30;
	$content =~ s/\n/␤/g;

	my $output = "";
	$output .= " " x $depth;
	$output .= $message;
	
	$output .= push_color($wrappingColor);
	$output .= " [";
	$output .= pop_color();
	
	$output .= $content;
	
	$output .= push_color($wrappingColor);
	if (10 < $contentLength)
	{
		$output .= "...".$contentLength;
	}
	
	$output .= "]";
	$output .= pop_color();
	
	$output .= "\n";
	
	warn $output;
}

sub parseContent
{
	my ($astContentRef, $grammar, $rule, @symbolStack) = @_;

	my ($type, @values) = @{$rule};
	
	my $symbol;
	if ($type eq '@')
	{
		$symbol = $values[0][1];
		push @symbolStack, $symbol;
	}
	
	
	if ($symbol)
	{
		log_parse("> ".$symbol, $$astContentRef, scalar @symbolStack);
	}
	
	my $astContent = $$astContentRef;
	
	my $ast = parseContentInner(\$astContent, $grammar, $rule, @symbolStack);
	
	if ($ast)
	{
		$$astContentRef = $astContent;
		if ($symbol)
		{
			log_parse("+ ".$symbol, $$astContentRef, scalar @symbolStack);
		}
		return $ast;
	}
	else
	{
		if ($symbol)
		{
			log_parse("- ".$symbol, $$astContentRef, scalar @symbolStack);
		}
		return;
	}
}

sub parseContentInner
{
	my ($astContentRef, $grammar, $rule, @symbolStack) = @_;

	my ($type, @values) = @{$rule};

	if ($type eq '^')	
	{
		return parseContent($astContentRef, $grammar, $values[0])
	}
	elsif ($type eq '@')
	{
		my ($symbol, $subrule) = @values;
		
		$times{$symbolStack[-2]}{''} -= time;		
		$times{$symbolStack[-2]}{$symbolStack[-1]} -= time;		
		
		my $ast = parseContent($astContentRef, $grammar, $subrule, @symbolStack);
		
		$counts{$symbolStack[-2]}{''}{'total'}++;
		$counts{$symbolStack[-2]}{''}{$ast?'success':'failure'}++;
		
		$counts{$symbolStack[-2]}{$symbolStack[-1]}{'total'}++;
		$counts{$symbolStack[-2]}{$symbolStack[-1]}{$ast?'success':'failure'}++;		
		
		$times{$symbolStack[-2]}{''} += time;	
		$times{$symbolStack[-2]}{$symbolStack[-1]} += time;	

		return [$symbol->[1], $ast] if defined $ast;
	}
	elsif ($type eq '&')
	{
		my @asts;
		foreach my $subrule (@values)
		{
			my $ast = parseContent($astContentRef, $grammar, $subrule, @symbolStack);
			return if !defined $ast;
			push @asts, $ast;
		}
		return [undef, @asts];
	}
	elsif ($type eq '*')
	{
		my ($subrule) = @values;
		my @asts;
		while (my $ast = parseContent($astContentRef, $grammar, $subrule, @symbolStack))
		{
			push @asts, $ast;
		}
		return [undef, @asts];
	}
	elsif ($type eq '+')
	{
		my ($subrule) = @values;
		my @asts;
		while (my $ast = parseContent($astContentRef, $grammar, $subrule, @symbolStack))
		{
			push @asts, $ast;
		}
		if (@asts)
		{
			return [undef, @asts];
		}
	}
	elsif ($type eq '|')
	{
		foreach my $subrule (@values)
		{
			my $ast = parseContent($astContentRef, $grammar, $subrule, @symbolStack);
			return [undef, $ast] if defined $ast;
		}
# 		return [undef];
	}
	elsif ($type eq '!')
	{
		my ($subrule) = @values;
		my $ast = parseContent($astContentRef, $grammar, $subrule, @symbolStack);
		return [undef, $ast] if defined $ast;
	}
	elsif ($type eq '?')
	{
		my ($subrule) = @values;
		my $ast = parseContent($astContentRef, $grammar, $subrule, @symbolStack);
		return [undef, $ast];
	}
	elsif ($type eq '/')
	{
		my ($regex) = @values;
		$regex =~ s!^/!!;
		$regex =~ s!/$!!;
		
		my $astContent = $$astContentRef;

		$astContent =~ s/^($regex)//;
		
		my $ast = $1;

		return if !length $ast;
		
		$$astContentRef = $astContent;
		return [undef, $ast];
	}
	elsif ($type eq '$')
	{
		my ($regex) = @values;
		$regex =~ s!^'!!;
		$regex =~ s!'$!!;
		
		my $astContent = $$astContentRef;
		
		$regex = quotemeta $regex;

		$astContent =~ s/^($regex)//;
		
		my $ast = $1;

		return if !length $ast;
		
		$$astContentRef = $astContent;
		return [undef, $ast];
	}
	elsif ($type eq '%')
	{
		my ($symbol) = @values;
		return parseContent($astContentRef, $grammar, grammarRule($grammar, $symbol), @symbolStack);
	}
	else
	{
		die "Unhandled grammar rule: ".Dumper($rule);
	}
	return;
}

sub grammarRule
{
	my ($grammar, $symbol) = @_;
	
	my ($type, @values) = @{$grammar};
	
	foreach my $rule (@values)
	{
		return $rule if $rule->[1][1] eq $symbol;
	}
	die "could not find rule: $symbol\n";	
}

sub optimiseAst
{
	my ($node, @symbols) = @_;

	if (ref $node)
	{
		my ($symbol, @subnodes) = @{$node};
		
		if (exists $stripSymbols{$symbol})
		{
			return;
		}
		
		my @optimisedSubnodes;
				
		push @symbols, $symbol if defined $symbol;
		foreach my $subnode (@subnodes)
		{
			push @optimisedSubnodes, optimiseAst($subnode, @symbols);
		}
		
		if (@optimisedSubnodes)
		{
			if (defined $symbol)
			{
				return [$symbol, @optimisedSubnodes];
			}
			else
			{
				return @optimisedSubnodes;
			}
		}
		
		return;
	}
	elsif (length $node)
	{
		return $node;
	}
	return;
}

sub encodeAst
{
	my ($node, @symbols) = @_;
	
	my $content = "";
	
	if (ref $node)
	{
		my ($symbol, @subnodes) = @{$node};

		if (defined $annotateStructure && defined $symbol)
		{
			$content .= push_color($wrappingColor);
			if ($annotateStructure eq 'stack')
			{
				$content .= "  " x scalar @symbols;
				$content .= $symbol;
			}
			else
			{
				$content .= "{";
			}
			
			if ($annotateStructure eq 'symbols')
			{
				$content .= $symbol;
			}
			$content .= pop_color();
			if ($annotateStructure eq 'stack')
			{
				$content .= "\n";
			}
		}	
			
		if (defined $symbol && exists $colors{$symbol})
		{
			$content .= push_color($colors{$symbol});
		}
	
		push @symbols, $symbol if defined $symbol;
		foreach my $subnode (@subnodes)
		{
			$content .= encodeAst($subnode, @symbols);
		}
		
		if (defined $symbol && exists $colors{$symbol})
		{
			$content .= pop_color();
		}
		
		if (defined $annotateStructure)
		{
			$content .= push_color($wrappingColor);
			if ($annotateStructure eq 'symbols')
			{
				$content .= $symbol;
			}
			
			if ($annotateStructure ne 'stack')
			{
				$content .= "}";
			}
			$content .= pop_color();
		}
	}
	else
	{
		if ($annotateStructure eq 'stack')
		{
			$content .= "  " x scalar @symbols;
		}
	
		if (defined $annotateStructure)
		{
			$content .= push_color($wrappingColor);
			$content .= "[";
			$content .= pop_color();
		}
	
		if ($annotateStructure eq 'stack')
		{
			$node =~ s/\n/␤/g;
		}
			
		$content .= $node;
		
		if (defined $annotateStructure)
		{
			$content .= push_color($wrappingColor);
			$content .= "]";
			$content .= pop_color();
		}
		
		if ($annotateStructure eq 'stack')
		{
			$content .= "\n";
		}
	}
	
	return $content;
}

return 1;