use strict;

our $showColors = 1;

my @color_stack;

my @grays = (16, 232, 233, 234, 235, 236, 237, 238, 239, 240, 59, 241, 242, 243, 244, 102, 245, 246, 247, 248, 145, 249, 250, 7, 251, 252, 188, 253, 254, 255, 231);

# RGB, 0-5 each non-linear so be careful

sub rgb_color
{
	my ($red, $green, $blue) = @_;
	return 16 + $blue + ($green * 6) + ($red * 36);
}

# Grayscale 0-30 non-linear so be careful

sub gray_color
{
	my ($gray) = @_;
	return $grays[$gray];
}

sub push_color
{
	return '' if !$showColors;
	# http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
	my ($index) = @_;
	push @color_stack, sprintf qq(\x1b[38;5;%dm), $index;
	return $color_stack[-1];
}
	
sub push_rgb_color
{
	return push_color(rgb_color(@_));
}

sub push_gray_color
{
	return push_color(gray_color(@_));
}

sub pop_color
{
	return '' if !$showColors;
	pop @color_stack;
	return $color_stack[-1];
}

sub reset_color_stack
{
# 		return '' if !$showColors;
	@color_stack = ("\x1b[0m");
	return $color_stack[-1];
}

reset_color_stack();

return 1;