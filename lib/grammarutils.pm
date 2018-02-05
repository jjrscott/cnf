use strict;
use utf8;

sub parseGrammar
{
	my ($contentRef, $depth) = @_;
	
	my $content = $$contentRef;
	
	my @rules;
	
	while (my $rule = parseRule(\$content, $depth+1))
	{
		push @rules, $rule;
	}
	
	skipWhitespace(\$content, $depth+1);
	
	if (@rules)
	{
		$$contentRef = $content;
		return ['^', @rules];
	}
	
	return;
}

sub parseRule
{
	my ($contentRef, $depth) = @_;
	
	my $content = $$contentRef;

	my $symbol = parseIdentifier(\$content, $depth+1) || return;
	
	testConstant(\$content, $depth+1, "=") || testConstant(\$content, $depth+1, "::=") ||return;
	
	my $terminals = parseOrTerminals(\$content, $depth+1) || parseAndTerminals(\$content, $depth+1);
	
	testConstant(\$content, $depth+1, ";") || return;
	
	$$contentRef = $content;
	
	return ['@', $symbol, $terminals];
}

sub parseAndTerminals
{
	my ($contentRef, $depth) = @_;
	
	my $content = $$contentRef;

	my @terminals;
	
	while (my $terminal = parseTerminal(\$content, $depth+1))
	{
		push @terminals, $terminal;
	}
	
	if (@terminals)
	{
		$$contentRef = $content;
		return ['&', @terminals];
	}
	
	return;
}

sub parseOrTerminals
{
	my ($contentRef, $depth) = @_;
	
	my $content = $$contentRef;

	my @terminals;
	
	{
		my $terminal = parseAndTerminals(\$content, $depth+1) || return;
		push @terminals, $terminal;
	}
		
	while (testConstant(\$content, $depth+1, "|"))
	{
		my $terminal = parseAndTerminals(\$content, $depth+1) || return;
		push @terminals, $terminal;
	}
	
	if (@terminals > 1)
	{
		$$contentRef = $content;
		return ['|', @terminals];
	}
	
	return;
}

sub parseTerminal
{
	my ($contentRef, $depth) = @_;
	
	foreach my $function (\&parseIdentifier, \&parseString, \&parseBracedTerminal)
	{
		my $content = $$contentRef;
		if (my $terminal = $function->(\$content, $depth+1))
		{
			my $terminalAttribute = "!";
			if (testConstant(\$content, $depth+1, "*"))
			{
				$terminalAttribute = "*";
			}
			elsif (testConstant(\$content, $depth+1, "+"))
			{
				$terminalAttribute = "+";
			}
			elsif (testConstant(\$content, $depth+1, "?"))
			{
				$terminalAttribute = "?";
			}

			$$contentRef = $content;
			return [$terminalAttribute, $terminal];
		}
	}
	return;
}

sub parseBracedTerminal
{
	my ($contentRef, $depth) = @_;
	
	my $content = $$contentRef;
	
	testConstant(\$content, $depth+1, "(") || return;
	
	my $terminals = parseOrTerminals(\$content, $depth+1) || parseAndTerminals(\$content, $depth+1) || return;
	
	testConstant(\$content, $depth+1, ")") || return;
	
	$$contentRef = $content;
	
	return $terminals;
}

sub parseIdentifier
{
	my ($contentRef, $depth) = @_;

	my $content = $$contentRef;

	skipWhitespace(\$content, $depth+1);

	if ($content =~ s/^([a-zA-Z_][a-zA-Z0-9_]*)//)
	{
		$$contentRef = $content;
		return ['%', $1,];
	}
	return;
}

sub parseString
{
	my ($contentRef, $depth) = @_;

	my $content = $$contentRef;

	skipWhitespace(\$content, $depth+1);
	
	if ($content =~ s/^("(?:\\.|[^"])*")//)
	{
		$$contentRef = $content;
		return ['$', $1];
	}
	
	if ($content =~ s/^('(?:\\.|[^'])*')//)
	{
		$$contentRef = $content;
		return ['$', $1];
	}
	
	if ($content =~ s!^(/(?:\\.|[^/])*/)!!)
	{
		$$contentRef = $content;
		return ['/', $1];
	}

	return;
}


sub skipWhitespace
{
	my ($contentRef, $depth) = @_;

	my $content = $$contentRef;
	
	while (1)
	{
		if ($content =~ s/^([ \t\n]+)//)
		{
			redo;
		}
		
		if ($content =~ s/^(\/\/[^\n]*\n)//)
		{
			redo;
		}
		
		if ($content =~ s/^(#[^\n]*\n)//)
		{
			redo;
		}
		
		if ($content =~ s/^(\/\*.*?\*\/)//s)
		{
			redo;
		}
	
		last;
	}

	$$contentRef = $content;

	return;
}

sub testConstant
{
	my ($contentRef, $depth, $constant) = @_;
	
	my $content = $$contentRef;
	
	skipWhitespace(\$content, $depth+1);

	my $stringIndex = index $content, $constant;
	if (0 == $stringIndex)
	{
		$$contentRef = substr $content, length $constant;
		return 1;
	}
	return;
}

sub grammarSymbols
{
	my ($node, $symbols) = @_;
	
	my ($type, @values) = @{$node};
	
	if ($type eq '^')
	{
		$symbols = {};
	}
	
	if ($type eq '%')
	{
		$symbols->{$values[0]} ||= undef;
		return $values[0];
	}
	elsif ($type ne '$' && $type ne '/')
	{
		foreach my $value (@values)
		{
			if (!ref $value)
			{
				die Dumper($node, $value);
			}
			my $symbol = grammarSymbols($value, $symbols);
			if ($type eq '@' && defined $symbol)
			{
				$symbols->{$symbol} = $node;
			}
		}		
	}
	
	if ($type eq '^')
	{
		return $symbols;
	}
	return;
}

sub optimizeGrammar
{
	my ($node) = @_;
	
	if (ref $node)
	{
		my ($type, @values) = @{$node};
		
		return $node;
	}
	else
	{
		return $node;
	}
}

sub encodeGrammar
{
	my ($grammar, $node, $maxSymbolLength, @types) = @_;
	
	my $content = "";

	if (!ref $node)
	{
		$content .= push_rgb_color(3,0,0);
		$content .= ">>> ".$node." <<<";
		$content .= pop_color();
	
		return $content;
	}	
	
	my ($type, @values) = @{$node};
	
	my $syntaxColor = gray_color(10);

	if ($type eq '^')	
	{
		my $symbols = grammarSymbols($grammar);
		my $maxSymbolLength = max(map {length} keys %{$symbols});
		
		foreach my $symbol ('__root', sort {lc $a cmp lc $b} grep {$_ ne '__root'} keys %{$symbols})
		{
			if ($symbols->{$symbol})
			{
				$content .= encodeGrammar($grammar, $symbols->{$symbol}, $maxSymbolLength, @types, $type);
				$content .= "\n";
			}
			else
			{
				$content .= encodeGrammar($grammar, ['@', ['%', $symbol], ['$', '...']], $maxSymbolLength, @types, $type);
				$content .= "\n";
			}
		}
	}
	elsif ($type eq '@')
	{
		my ($symbol, $definition) = @values;
		my $symbolLength = $maxSymbolLength + length encodeGrammar($grammar, ['%','']);
		$content .= sprintf qq(%${symbolLength}s), encodeGrammar($grammar, $symbol, $maxSymbolLength, @types, $type);
		$content .= " ";
		$content .= push_color($syntaxColor);
		$content .= "=";
		$content .= pop_color();
		$content .= " ";
		$content .= encodeGrammar($grammar, $definition, $maxSymbolLength, @types, $type);
		$content .= push_color($syntaxColor);
		$content .= ";";
		$content .= pop_color();
	}
	elsif ($type eq '%')
	{
		$content .= push_rgb_color(0, 0, 1);
		$content .= $values[0];
		$content .= pop_color();	
	}
	elsif ($type eq '$' || $type eq '/')
	{
		$content .= push_rgb_color(3,0,0);
		$content .= $values[0];
		$content .= pop_color();
	}
	elsif ($type eq '|')
	{
		return encodeGrammar($grammar, $values[0], $maxSymbolLength, @types) if (1 == @values) && ref $values[0];
	
		$content .= push_color($syntaxColor);
		if ($types[-1] ne '@')
		{
			$content .= '(';
		}
		
		for (my $index=0; $index<@values; $index++)
		{
			if ($index > 0)
			{
				if ($types[-1] eq '@')
				{
					$content .= "\n" . (' ' x $maxSymbolLength) . ' | ';
				}
				else
				{
					$content .= ' | ';
				}
			}
			$content .= encodeGrammar($grammar, $values[$index], $maxSymbolLength, @types, $type);
		}
		
		if ($types[-1] eq '@')
		{
			$content .= "\n" . (' ' x $maxSymbolLength  . ' ');
		}
		
		if ($types[-1] ne '@')
		{
			$content .= ')';
		}
		$content .= pop_color();
	}
	elsif ($type eq '&')
	{
		return encodeGrammar($grammar, $values[0], $maxSymbolLength, @types) if (1 == @values) && ref $values[0];
		$content .= push_color($syntaxColor);
		if ($types[-1] ne '@')
		{
			$content .= '(';
		}
		$content .= join ' ', map {encodeGrammar($grammar, $_, $maxSymbolLength, @types, $type)} @values;
		if ($types[-1] ne '@')
		{
			$content .= ')';
		}
		$content .= pop_color();
		
	}
	elsif ($type eq '!')
	{
		$content .= encodeGrammar($grammar, $values[0], $maxSymbolLength, @types, $type);
	}
	elsif ($type eq '?' || $type eq '*' || $type eq '+')
	{
		$content .= encodeGrammar($grammar, $values[0], $maxSymbolLength, @types, $type);
		$content .= push_color($syntaxColor);
		$content .= $type;
		$content .= pop_color();
	}
	else
	{
		die $type;
	}

	return $content;
}

return 1;