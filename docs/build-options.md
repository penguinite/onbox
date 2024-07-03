---
title: "Build options"
description: "This page documents all the different build options that are available when building Pothole."
---

This page documents all the different build options we have. You should be able to just append this directly to the `nimble build` command and have it work.

2. `-d:phLang`, optional (defaults to "en"), Accepts a string.

This flag tells Pothole what language to use for its instance pages. 

The following languages are available:
| language | code |
|----------|------|
| English  | en |
| Danish | da |

Though you can simply change the static assets at runtime. So this option is not all that important.

3. `-d:phVersion`, optional, Accepts a string.

This flag allows you to change the version hardcoded into pothole.