Aliasify is a [transform](https://github.com/substack/node-browserify#btransformtr) for [browserify](https://github.com/substack/node-browserify) which lets you rewrite calls to `require`. This is an alternative, with more configuration options, to the [`browser` field](https://gist.github.com/defunctzombie/4339901#replace-specific-files---advanced) [interpreted](https://github.com/substack/node-browserify#packagejson) by browserify.

Installation
============

Install with `npm install --save-dev aliasify`.

Usage
=====

To use, add a section to your package.json:

    {
        "aliasify": {
            aliases: {
                "d3": "./shims/d3.js"
                "underscore": "lodash"
            }
        }
    }

Now if you have a file in src/browserify/index.js which looks like:

    d3 = require('d3')
    _ = require('underscore')
    ...

This will automatically be transformed to:

    d3 = require('../../shims/d3.js')
    _ = require('lodash')
    ...

Any replacement that starts with a "." will be resolved as a relative path (as "d3" above.)  Replacements that start with any other character will be replaced verbatim (as with "underscore" above.)

Configuration
=============

Configuration can be loaded in multiple ways;  You can put your configuration directly in package.json, as in the example above, or you can use an external json or js file.  In your package.json:

    {
        "aliasify": "./aliasifyConfig.js"
    }

Then in aliasifyConfig.js:

    module.exports = {
        aliases: {
            "d3": "./shims/d3.js"
        },
        verbose: false
    };

Note that using a js file means you can change your configuration based on environment variables.

Alternatively, if you're using the Browserify API, you can configure your aliasify programatically:

    aliasify = require('aliasify').configure({
        aliases: {
            "d3": "./shims/d3.js"
        },
        configDir: __dirname,
        verbose: false
    });

note that `configure()` returns a new `aliasify` instance.

Configuration options:
* `aliases` - An object mapping aliases to their replacements.
* `verbose` - If true, then aliasify will print modificiations it is making to stdout.
* `configDir` - An absolute path to resolve relative paths against.  If you're using package.json,
  this will automatically be filled in for you with the directory containing package.json.

