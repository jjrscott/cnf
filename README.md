# C<span style="margin-left:-0.3em;font-size:70%;vertical-align: 10%;">♭</span>

C<span style="margin-left:-0.25em;font-size:70%;vertical-align: 9%;">♭</span> (C Flat) is a style of C that prioritises easy parsing over human readability.

Many IDEs show a modified version of the raw source. For example:

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

 

1. C<span style="margin-left:-2px;font-size:70%;vertical-align: 1px;">♭</span> is strict subset of C.
1. <code class="language-c">/* ... */</code> and <code class="language-c">// ...</code> are checked for first.
1.  <code class="language-c">( ... )</code>, <code class="language-c">{ ... }</code> and <code class="language-c">( ... )</code> MUST be matched.
1. The characters `()[]{}` can not be used anywhere else accept in comments.
<!--4. All variables MUST be prefixed with `$`.
-->

