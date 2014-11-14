path = require 'path'
transformTools = require 'browserify-transform-tools'

getReplacement = (file, aliases)->
    if aliases[file]
        return aliases[file]
    else
        fileParts = /^([^\/]*)(\/.*)$/.exec(file)
        pkg = aliases[fileParts?[1]]
        if pkg?
            return pkg+fileParts[2]
    return null

module.exports = transformTools.makeRequireTransform "aliasify", {jsFilesOnly: true, fromSourceFileDir: true}, (args, opts, done) ->
    if !opts.config then return done new Error("Could not find configuration for aliasify")
    aliases = opts.config.aliases
    verbose = opts.config.verbose
    configDir = opts.configData?.configDir or opts.config.configDir or process.cwd()

    result = null

    file = args[0]
    if file? and aliases?
        replacement = getReplacement(file, aliases)
        if replacement?
            if replacement.relative?
                replacement = replacement.relative

            else if /^\./.test(replacement)
                # Resolve the new file relative to the configuration file.
                replacement = path.resolve configDir, replacement
                fileDir = path.dirname opts.file
                replacement = "./#{path.relative fileDir, replacement}"

            if verbose
                console.log "aliasify - #{opts.file}: replacing #{args[0]} with #{replacement}"

            result = "require('#{replacement.replace(/\\/gi,"/")}')"

    done null, result
