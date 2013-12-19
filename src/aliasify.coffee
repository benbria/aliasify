path = require 'path'
transformTools = require 'browserify-transform-tools'

module.exports = transformTools.makeRequireTransform "aliasify", (args, opts, cb) ->
    config = opts.config
    if args.length > 0 and config[args[0]]?
        replacement = config[args[0]]

        # Resolve the new file relative to the file doing the requiring.
        replacement = path.resolve opts.configDir, replacement
        fileDir = path.dirname opts.file
        relative = path.relative fileDir, replacement

        cb null, "require('#{relative}')"
    else
        cb()
