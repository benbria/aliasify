require('es6-promise').polyfill()

path = require 'path'
assert = require 'assert'
transformTools = require 'browserify-transform-tools'
Mocha = require 'mocha'
pb = require 'promise-breaker'
aliasify = require '../src/aliasify'
testDir = path.resolve __dirname, "../testFixtures/test"
testWithRelativeConfigDir = path.resolve __dirname, "../testFixtures/testWithRelativeConfig"

runTestWithConfig = pb.make (aliasifyConfig, content=null, done) ->
    process.chdir testDir
    jsFile = path.resolve __dirname, "../testFixtures/test/src/index.js"
    options = {config: aliasifyConfig}
    if content then options.content = content
    transformTools.runTransform aliasify, jsFile, options, done

runTestWithCustomAliases = pb.make (aliasifyConfig, content=null, requireAliases=[], done) ->
    process.chdir testDir
    jsFile = path.resolve __dirname, "../testFixtures/test/src/foobar/foobar.js"
    options = {config: aliasifyConfig}
    if content then options.content = content
    aliasifyWithRequierishFunctions = aliasify.requireish(requireAliases)
    transformTools.runTransform aliasifyWithRequierishFunctions, jsFile, options, done

describe "aliasify", ->
    cwd = process.cwd()

    after ->
        process.chdir cwd

    it "should correctly transform a file", (done) ->
        process.chdir testDir
        jsFile = path.resolve __dirname, "../testFixtures/test/src/index.js"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = require('./../shims/d3.js');
                _ = require('lodash');
            """)
            done()

    it "should correctly transform a file when the configuration is in a different directory", (done) ->
        process.chdir testWithRelativeConfigDir
        jsFile = path.resolve __dirname, "../testFixtures/testWithRelativeConfig/src/index.js"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal result, "d3 = require('./../shims/d3.js');"
            done()

    it "should allow configuration to be specified programatically", ->
        runTestWithConfig {aliases: {"d3": "./foo/baz.js"}}
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = require('./../foo/baz.js');
                _ = require("underscore");
            """)

    it "should allow removal of requires", ->
        runTestWithConfig {aliases: {"d3": false}}
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = {};
                _ = require("underscore");
            """)

    it "should allow removal of requires from code with path after alias", ->
        runTestWithConfig(
            {aliases: {"d3": false}},
            """
                d3 = require("d3/suffix.js");
                _ = require("underscore");
            """
        )
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = {};
                _ = require("underscore");
            """)

    it "should allow removal of requires via regex", ->
        runTestWithConfig {replacements: {"^d3$": false}, aliases: {}}
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = {};
                _ = require("underscore");
            """)

    it "should work if there are regexes and no aliases", ->
        runTestWithConfig {
            aliases: null
            replacements: {
                "d3.*": "./foo/baz.js"
            }
        }
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = require('./../foo/baz.js');
                _ = require("underscore");
            """)

    it "should work if there are no regexes and no aliases", ->
        runTestWithConfig {
            aliases: null
            replacements: null
        }
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = require("d3");
                _ = require("underscore");
            """)

    it "should allow configuration to be specified using legacy 'configure' method", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/index.js"
        aliasifyWithConfig = aliasify.configure {
            aliases: {
                "d3": "./foo/bar.js"
            },
            configDir: path.resolve __dirname, "../testFixtures/test"
        }

        transformTools.runTransform aliasifyWithConfig, jsFile, (err, result) ->
            return done err if err
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = require('./../foo/bar.js');
                _ = require("underscore");
            """)
            done()

    it "should allow paths after an alias", ->
        runTestWithConfig(
            {
                aliases: {"d3": "./base/"}
                configDir: path.resolve __dirname, "../testFixtures/test"
            },
            """
                d3 = require("d3/suffix.js");
                _ = require("underscore");
            """
        ).then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                d3 = require('./../base/suffix.js');
                _ = require("underscore");
            """)

    it "should allow paths after an alias2", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/index.js"

        aliasifyWithConfig = aliasify.configure {
            aliases: {
                "d3": "./foo/"
            },
            configDir: path.resolve __dirname, "../testFixtures/test"
        }

        content = Mocha.utils.clean("""
            d3 = require("d3/bar.js");
        """)
        expectedContent = Mocha.utils.clean("""
            d3 = require('./../foo/bar.js');
        """)

        transformTools.runTransform aliasifyWithConfig, jsFile, {content}, (err, result) ->
            return done err if err
            assert.equal result, expectedContent
            done()



    it "passes anything that isn't javascript along", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/package.json"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""{
                "aliasify": {
                    "aliases": {
                        "d3": "./shims/d3.js",
                        "underscore": "lodash"
                    }
                }
            }
            """)
            done()

    it "passes supports relative path option", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/bar/bar.js"

        aliasifyWithConfig = aliasify.configure {
            aliases: {
                "foo": { relative: "../foo/foo.js" }
            }
        }

        expectedContent = Mocha.utils.clean("""
            var foo = require('../foo/foo.js');
        """)

        transformTools.runTransform aliasifyWithConfig, jsFile, (err, result) ->
            return done err if err
            assert.equal result, expectedContent
            done()

    it "supports nested packages", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/testNestedPackages/node_modules/inner-package/foo/foo.js"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal result, "d3 = require('./../shims/d3.js');"
            done()

    it "supports the react case that everyone is asking for", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/react/includeReact.js"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                react1 = require('react/addons');
                react2 = require('react/addons');
            """)
            done()

    it "should correctly resolve Windows absolute paths", (done) ->
        jsFile = "c:\\foo.js"

        aliasifyWithConfig = aliasify.configure {
            aliases: {
                "foo": jsFile
            }
        }

        content = Mocha.utils.clean("""
            foo = require("foo");
        """)
        # Note the \\\\ here, because this is in "s, but this resolves to a double \\.
        # The double \\ is still needed, since \\ inside of ''s resolves to a single \ in the end.
        expectedContent = Mocha.utils.clean("""
            foo = require('c:\\\\foo.js');
        """)

        transformTools.runTransform aliasifyWithConfig, jsFile, {content}, (err, result) ->
            return done err if err
            assert.equal result, expectedContent
            done()

    it "should correctly resolve absolute paths", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/foo/foo.js"

        aliasifyWithConfig = aliasify.configure {
            aliases: {
                "foo": jsFile
            }
        }

        content = Mocha.utils.clean("""
            foo = require("foo");
        """)
        expectedContent = Mocha.utils.clean("""
            foo = require('#{jsFile.replace(/\\/gi, '\\\\')}');
        """)

        transformTools.runTransform aliasifyWithConfig, jsFile, {content}, (err, result) ->
            return done err if err
            assert.equal result, expectedContent
            done()

    it "should correctly replace a RexExp alias", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/regexp.js"
        aliasifyWithConfig = aliasify.configure {
            replacements: {
                "_components/(\\w+)": "src/components/$1.jsx"
            }
        }

        expectedContent = Mocha.utils.clean("""
            SomeComponent = require('src/components/SomeComponent.jsx');
        """)

        transformTools.runTransform aliasifyWithConfig, jsFile, (err, result) ->
            return done err if err
            assert.equal result, expectedContent
            done()

    it "should correctly replace a RexExp alias function", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/regexp.js"
        aliasifyWithConfig = aliasify.configure {
            replacements: {
                "_components/(\\w+)": (alias, regexMatcher, regexObject) ->
                    return "src/silly.js"
            }
        }

        expectedContent = Mocha.utils.clean("""
            SomeComponent = require('src/silly.js');
        """)

        transformTools.runTransform aliasifyWithConfig, jsFile, (err, result) ->
            return done err if err
            assert.equal result, expectedContent
            done()

    it "should correctly replace multiple RexExp alias functions (scoping)", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/regexp2.js"
        aliasifyWithConfig = aliasify.configure {
            replacements: {
                "_component/(.*)": (alias, regexMatcher, regexObject) ->
                    return alias.replace(regexObject, 'src/silly.js')
                "_store/(.*)": (alias, regexMatcher, regexObject) ->
                    return alias.replace(regexObject, 'src/stores/$1/index.js')

            }
        }

        expectedContent = Mocha.utils.clean("""
            SomeComponent = require('src/silly.js');
            SomeStore = require('src/stores/SomeStore/index.js');
        """)

        transformTools.runTransform aliasifyWithConfig, jsFile, (err, result) ->
            return done err if err
            assert.equal Mocha.utils.clean(result), expectedContent
            done()

    
    it "should support aliasing require calls by a string", ->
        runTestWithCustomAliases {aliases: "foo": { relative: "../foo/foo.js" }}, null, 'foobar'
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                var foo = foobar('../foo/foo.js');
                var qux = baz('foo');
            """)
    
    it "should support aliasing require calls by an array of strings", ->
        runTestWithCustomAliases {aliases: "foo": { relative: "../foo/foo.js" }}, null, ['foobar', 'baz']
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                var foo = foobar('../foo/foo.js');
                var qux = baz('../foo/foo.js');
            """)

    it "should preserve args other than the first", ->

        content = Mocha.utils.clean("""
                var foo = foobar('foo', 'baz', bar, function (){}, {}, []);
            """)
    
        runTestWithCustomAliases {aliases: "foo": { relative: "../foo/foo.js" }}, content, 'foobar'
        .then (result) ->
            assert.equal Mocha.utils.clean(result), Mocha.utils.clean("""
                var foo = foobar('../foo/foo.js', 'baz', bar, function (){}, {}, []);
            """)
    
