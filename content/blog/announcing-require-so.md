+++
title = "require_so: DRYer StackOverflow copying"
date = 2020-05-20
aliases = ["/molten-matter/announcing-require-so"]

[taxonomies]
tags = ["ruby", "shitpost"]
+++

Today I was reading [a post on the StackOverflow blog](https://stackoverflow.blog/2020/05/20/good-coders-borrow-great-coders-steal/?cb=1)
when I was struck by this passage:

> Copying code from Stack Overflow is a form of code cloning

Code **cloning**, you say? In **my** DRY Ruby codebase? Not if *I* can help it!

And so I got to work. After extensive research, I concluded that deleting the snippet from StackOverflow
to make my version the canonical one was not a viable option.

![](how-to-delete.jpg)

So I flipped the problem on its head: why not make the StackOverflow version the canonical one?
And thus, [require_so](https://github.com/steinuil/require_so) was born.

## How do I use it?

Locate the code snippet

![It's right there](answer.jpg)

Copy the short permalink below the StackOverflow answer

![Copy that shit](share.jpg)

Paste it into your code

```ruby
require "require_so"
require_so "https://stackoverflow.com/a/61879644"
```

And voilà, the methods defined in the snippet will be brought into scope.

```ruby
fast_next_smaller(907) #=> 790
```

No more code cloning!

