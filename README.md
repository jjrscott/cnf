# C Normal Form


C Normal Form is an ongoing attempt to create a style of C that prioritises trivial machine parsing over human readability. 

It performs this feat by simplifying C's grammar down so that it only requires a simple set of rules and operations. 

For example, All statements must end with `;`. This includes `if`, `while`, `for` statements:

```c
int main(void)
{
	if (5)
	{
		return(10);
	}
	else
	{
		return(5);
	};
};
```

This may seem pointless but it means that the parser does not need to understand any more context than "split on `;`" to separate statements and function definitions. As inferred in the next section none of what you see need be what is actually on disk. In fact, the on-disk code would be in a cannonical form such as:

```c
int main(void){if(5){return(10);}else{return(5);};};
```

But since the parser is so simple it can be implemented in any language, whatever your IDE or diff UI (eg SourceTree) was written in. What you actually see can be whatever your wish.

## Why this is not worse

Many IDEs show a modified version of the raw source. Below are a few of the visual tricks IDEs can do to make your life easier:

#### Ligations

[FiraCode](https://github.com/tonsky/FiraCode) uses [typographical ligatures](https://en.wikipedia.org/wiki/Typographic_ligature) to display <code class="language-c token operator">&gt;=</code> as <code class="language-c token operator">≥</code>. 



#### Lamda expressions

Android Studio displays Runnables as lamda expressions. So

```java
Observable.just("Hello, world!")  
   .subscribe(new Action1<String>() {
       @Override
       public void call(String s) {
           Log.d(TAG, s);
       }
   });
```

is displayed as

```java
Observable.just("Hello, world!")  
   .subscribe(s -> Log.d(TAG, s));

```
(via [Envato Tuts+](https://code.tutsplus.com/tutorials/java-8-for-android-cleaner-code-with-lambda-expressions--cms-29661))

#### Parameter Names Hinting

RubyMine has a feature that displays a method's parameter names at point of use. So

```ruby
count_letters(first_word, 1)
```

is displayed as

```ruby
count_letters(aword: first_word, incrementer: 1)
```

(via [RubyMine 2018.1 Help](https://www.jetbrains.com/help/ruby/type-hinting-in-product.html))

## Rules

Here's a summary of most of the rules:

1. CNF is strict subset of C.
1. `/* ... */` and `// ...` are checked for first.
1.  `( ... )`, `{ ... }` and `( ... )` MUST be matched.
1. The characters `()[]{}` can not be used anywhere else accept in comments.
1. All statements MUST end with `;`. This includes `if`, `while`, `for` statements, and function definitions.
1. All blocks MUST be wrapped in `{ ... }`. `if (foo) baa();` is NOT allowed. (The correct form is `if (foo) { baa(); };`)
1. Any keyword may only exists in the [C Operator Precedence Table](http://www.difranco.net/compsci/C_Operator_Precedence_Table.htm) once. To that end `++` and `--` are disallowed to avoid confusion of where it should really be.