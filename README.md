Aliasify is a [transform](https://github.com/substack/node-browserify#btransformtr) for [browserify](https://github.com/substack/node-browserify) which lets you rewrite calls to `require`.

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

Configuration is done via package.json.  You can either put your configuration directly in package.json, as in the example above, or you can use a json, js.  In your package.json:

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

Configuration options:
* `aliases` - An object mapping aliases to their replacements.
* `verbose` - If true, then aliasify will print modificiations it is making to stdout.

