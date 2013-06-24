# tmhOAuth

An OAuth library written in PHP by @themattharris.

**Disclaimer**: This project is a work in progress. Please use the issue tracker
to report any enhancements or issues you encounter.

## Goals

- Support OAuth 1.0A
- Use Authorisation headers instead of query string or POST parameters
- Allow uploading of images
- Provide enough information to assist with debugging

## Dependencies

The library has been tested with PHP 5.3+ and relies on CURL and hash_hmac. The
vast majority of hosting providers include these libraries and run with PHP 5.1+.

The code makes use of hash_hmac, which was introduced in PHP 5.1.2. If your version
of PHP is lower than this you should ask your hosting provider for an update.

## A note about security and SSL

Version 0.60 hardened the security of the library and defaulted `curl_ssl_verifypeer` to `true`.
As some hosting providers do not provide the most current certificate root file
it is now included in this repository. If the version is out of date OR you prefer
to download the certificate roots yourself, you can get them
from: http://curl.haxx.se/ca/cacert.pem

If you are getting http code 0 responses inspect `$tmhOAuth->response['error']` to see what the
problem is. usually code 0 means cacert.pem cannot be found, and it can be fixed by putting cacert.pem
in the location tmhOAuth is looking for it (indicated in the `$tmhOAuth->response['error']` message), or
by setting `$tmhOAuth->config['curl_cainfo']` and `$tmhOAuth->config['curl_capath']` values. setting
`$tmhOAuth->config['use_ssl']` to false *IS NOT* the way to solve this problem.

## Usage

This will be built out later but for the moment review the examples repository
<https://github.com/themattharris/tmhOAuthExamples> for ways the library can be
used. Each example contains instructions on how to use it.

For guidance on how to use [composer](http://getcomposer.org) to install tmhOAuth see the
[tmhOAuthExamples](https://github.com/themattharris/tmhOAuthExamples) project.

## Notes for users of previous versions

As of version 0.8.0 tmhUtilities is no longer included. If you found them useful open an issue against me
and i'll create a new repository for them. version 0.8.0 also ignores `$tmhOAuth->config['v']`. if you used
this before you should instead specify the API version in the path you pass to `$tmhOAuth->url`

Versions prior to 0.7.3 collapsed headers with the same value into one
`$tmhOAuth->response['headers']` key. Since 0.7.3 headers with the same key will use an array
to store their values.

If you previously used version 0.4 be aware the utility functions
have now been broken into their own file. Before you use version 0.5+ in your app
test locally to ensure your code doesn't need tmhUtilities included.

If you used custom HTTP request headers when they were defined as `'key: value'` strings
you should now define them as `'key' => 'value'` pairs.

## Change History

This is now published on the tmhOAuth wiki <https://github.com/themattharris/tmhOAuth/wiki/Change-History>

## Community

License: Apache 2 (see [included LICENSE file](https://github.com/themattharris/tmhOAuth/blob/master/LICENSE))

Follow [@tmhOAuth](https://twitter.com/intent/follow?screen_name=tmhOAuth) to receive updates on releases, or ask for support
Follow me on Twitter: [@themattharris](https://twitter.com/intent/follow?screen_name=themattharris)
Check out the Twitter Developer Resources: <https://dev.twitter.com>