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

module.exports = transformTools.makeRequireTransform "aliasify", (args, opts, cb) ->
    aliases = opts.config?.aliases
    verbose = opts.config?.verbose
    file = args[0]
    if file? and aliases?
        replacement = getReplacement(file, aliases)
        if replacement?
            if /^\./.test(replacement)
                # Resolve the new file relative to the file doing the requiring.
                replacement = path.resolve opts.configData.configDir, replacement
                fileDir = path.dirname opts.file
                replacement = "./#{path.relative fileDir, replacement}"

            if verbose
                console.log "aliasify - #{opts.file}: replacing #{args[0]} with #{replacement}"

            cb null, "require('#{replacement}')"
        else
            cb()
    else
        cb()
