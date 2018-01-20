# Instagram crawler

## Description

A simple Ruby script to download the full content of an instagram account or
recent and top posts of an hashtag.

It currently doesn't support downloading stories.

## Compatibility

Tested on Ruby 2.5 but should work with previous versions.
Tested on:
* Windows 10 x64
* Linux x64

## Usage

Install Ruby on your computer and launch the following command:

```
ruby ./instagram_crawler.rb [USERNAME...] [#HASHTAG...]
```

You can put any number of usernames and hashtags in any order.

It will download the content of the instagram account or hashtag to
`./username/*` or `./#hashtag/*`. The files will be named by their instagram
id followed by .jpg for images and .mp4 for videos. For instagram accounts it
will also download the profile picture to `./username/profile.jpg`.

### Examples

On Bash to use it you can do:
```sh
./instagram_crawler.rb adrientoub '#ruby' microsoft '#bash'
# or
./instagram_crawler.rb adrientoub \#ruby microsoft \#bash
```

On Powershell to use it you can do:
```powershell
ruby .\instagram_crawler.rb adrientoub "#ruby" microsoft "#powershell"
```
