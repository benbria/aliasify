path = require 'path'
transformTools = require 'browserify-transform-tools'

# Returns replacement require, `null` to not change require, `false` to replace require with `{}`.
getReplacement = (file, aliases, regexps) ->
    if regexps?
        for key of regexps
            re = new RegExp(key)
            if re.test(file)
                if regexps[key] == false
                    return false
                else if typeof regexps[key] == "function"
                    return regexps[key](file, key, re)
                else
                    return file.replace(re, regexps[key])

    if aliases?
        if file of aliases
            return aliases[file]
        else
            fileParts = /^([^\/]*)(\/.*)$/.exec(file)
            if fileParts?[1] of aliases
                pkg = aliases[fileParts?[1]]
                if pkg == false
                    return false
                else if pkg?
                    return pkg+fileParts[2]

    return null

module.exports = transformTools.makeRequireTransform "aliasify", {jsFilesOnly: true, fromSourceFileDir: true}, (args, opts, done) ->
    if !opts.config then return done new Error("Could not find configuration for aliasify")
    aliases = opts.config.aliases
    regexps = opts.config.replacements
    verbose = opts.config.verbose

    configDir = opts.configData?.configDir or opts.config.configDir or process.cwd()

    result = null

    file = args[0]
    if file? and (aliases? or regexps?)
        replacement = getReplacement(file, aliases, regexps)
        if replacement == false
            result = "{}"
        else if replacement?
            if replacement.relative?
                replacement = replacement.relative

            else if /^\./.test(replacement)
                # Resolve the new file relative to the configuration file.
                replacement = path.resolve configDir, replacement
                fileDir = path.dirname opts.file
                replacement = "./#{path.relative fileDir, replacement}"

            if verbose
                console.error "aliasify - #{opts.file}: replacing #{args[0]} with #{replacement}"

            # If this is an absolute Windows path (e.g. 'C:\foo.js') then don't convert \s to /s.
            if /^[a-zA-Z]:\\/.test(replacement)
                replacement = replacement.replace(/\\/gi, "\\\\")
            else
                replacement = replacement.replace(/\\/gi, "/")

            result = "require('#{replacement}')"

    done null, result
