---
title: "Potcode (is now obsolete)"
---

*Context:* Potcode was a small programming language that allowed users to change the HTML syntax of their user pages.

It worked like this:

```
<h1>{{ .Title }}</h1>
<p>List:</p>
<ul>
{{ :For x in .List }}
    <li>{{x}}</li>
{{ :End }}
</ul>
```

I was spending too much time working on it, it might be revived one day if enough people want that.
But it also is a terrible idea to implement a small programming language interpreter into a microblogging server.
Thus, Potcode is now obsolete and replaced by hardcoded templates and the ability to customize user CSS styling.