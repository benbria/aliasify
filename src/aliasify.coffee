path = require 'path'
transformTools = require 'browserify-transform-tools'

module.exports = transformTools.makeRequireTransform "aliasify", (args, opts, done) ->
    if !opts.config then return done new Error("Could not find configuration for aliasify")
    aliases = opts.config.aliases
    verbose = opts.config.verbose
    configDir = opts.configData?.configDir or opts.config?.configDir or process.cwd

    if (args.length > 0) and aliases? and aliases[args[0]]?
        replacement = aliases[args[0]]

        if replacement.length > 0 and replacement[0] is '.'
            # Resolve the new file relative to the file doing the requiring.
            replacement = path.resolve configDir, replacement
            fileDir = path.dirname opts.file
            replacement = "./#{path.relative fileDir, replacement}"

        if verbose
            console.log "aliasify - #{opts.file}: replacing #{args[0]} with #{replacement}"

        done null, "require('#{replacement}')"
    else
        done()
