path = require 'path'
transformTools = require 'browserify-transform-tools'

TRANSFORM_NAME = "aliasify"

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

makeTransform = (requireAliases) ->
    transformTools.makeFunctionTransform TRANSFORM_NAME, {
        jsFilesOnly: true,
        fromSourceFileDir: true,
        functionNames: requireAliases
    }, (functionParams, opts, done) ->
        if !opts.config then return done new Error("Could not find configuration for aliasify")
        aliases = opts.config.aliases
        regexps = opts.config.replacements
        verbose = opts.config.verbose
        absolutePaths = opts.config.absolutePaths

        configDir = opts.configData?.configDir or opts.config.configDir or process.cwd()

        result = null

        file = functionParams.args[0].value
        if file? and (aliases? or regexps?)
            replacement = getReplacement(file, aliases, regexps)
            if replacement == false
                result = "{}"
            else if replacement?
                if replacement.relative?
                    replacement = replacement.relative

                else if /^\./.test(replacement)
                    # Resolve the new file relative to the configuration file or system absolute
                    replacement = path.resolve configDir, replacement
                    if !absolutePaths
                        fileDir = path.dirname opts.file
                        replacement = "./#{path.relative fileDir, replacement}"

                if verbose
                    console.error "aliasify - #{opts.file}: replacing #{file} with #{replacement} " +
                        "of function #{functionParams.name}"

                # If this is an absolute Windows path (e.g. 'C:\foo.js') then don't convert \s to /s.
                if /^[a-zA-Z]:\\/.test(replacement)
                    replacement = replacement.replace(/\\/gi, "\\\\")
                else
                    replacement = replacement.replace(/\\/gi, "/")

                result = "'#{replacement}'"


        # Check if the function has more than one arg. If so preserve the remaining ones.
        if result? and result isnt "{}"
            remainingArgs = functionParams.args.slice(1)
            if remainingArgs.length > 0
                for arg in remainingArgs
                    if arg.type is "Literal"
                        result += ", '#{arg.value}'"
                    else if arg.type is "ObjectExpression"
                        try
                            result += ", #{JSON.stringify arg.value}"
                        catch err
                            result += ", #{JSON.stringify {}}"
                    else if arg.type is "ArrayExpression"
                        try
                            result += ", #{JSON.stringify arg.value}"
                        catch err
                            result += ", #{JSON.stringify []}"
                    else
                        result += ", #{arg.value}"
            result = "#{functionParams.name}(#{result})"

        done null, result

module.exports = (file, config) ->
    requireish = null
    if config and "requireish" of config
        requireish = config.requireish
    else
        configData = transformTools.loadTransformConfigSync TRANSFORM_NAME, file, {fromSourceFileDir: true}
        if configData and configData.config and "requireish" of configData.config
            requireish = configData.config.requireish

    wrappedTransform = makeTransform(requireish or ['require'])
    return wrappedTransform(file, config)

module.exports.configure = (config) ->
    return (file) -> module.exports file, config
