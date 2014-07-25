path = require 'path'
assert = require 'assert'
transformTools = require 'browserify-transform-tools'

aliasify = require '../src/aliasify'
testDir = path.resolve __dirname, "../testFixtures/test"
testWithRelativeConfigDir = path.resolve __dirname, "../testFixtures/testWithRelativeConfig"

describe "aliasify", ->
    cwd = process.cwd()

    after ->
        process.chdir cwd

    it "should correctly transform a file", (done) ->
        process.chdir testDir
        jsFile = path.resolve __dirname, "../testFixtures/test/src/index.js"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal result, """
                d3 = require('./../shims/d3.js');
                _ = require('lodash');
            """
            done()

    it "should correctly transform a file when the configuration is in a different directory", (done) ->
        process.chdir testWithRelativeConfigDir
        jsFile = path.resolve __dirname, "../testFixtures/testWithRelativeConfig/src/index.js"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal result, "d3 = require('./../shims/d3.js');"
            done()

    it "should allow configuration to be specified programatically", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/index.js"
        aliasifyWithConfig = aliasify.configure {
            aliases: {
                "d3": "./foo/bar.js"
            },
            configDir: path.resolve __dirname, "../testFixtures/test"
        }

        transformTools.runTransform aliasifyWithConfig, jsFile, (err, result) ->
            return done err if err
            assert.equal result, """
                d3 = require('./../foo/bar.js');
                _ = require("underscore");
            """
            done()

    it "should allow paths after an alias", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/index.js"

        aliasifyWithConfig = aliasify.configure {
            aliases: {
                "d3": "./foo/"
            },
            configDir: path.resolve __dirname, "../testFixtures/test"
        }

        content = """
            d3 = require("d3/bar.js");
        """
        expectedContent = """
            d3 = require('./../foo/bar.js');
        """

        transformTools.runTransform aliasifyWithConfig, jsFile, {content}, (err, result) ->
            return done err if err
            assert.equal result, expectedContent
            done()

    it "passes anything that isn't javascript along", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/package.json"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal result, """{
                "aliasify": {
                    "aliases": {
                        "d3": "./shims/d3.js",
                        "underscore": "lodash"
                    }
                }
            }
            """
            done()

    it "passes supports relative path option", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/bar/bar.js"
               
        aliasifyWithConfig = aliasify.configure {
            aliases: {
                "foo": { relative: "../foo/foo.js" }
            }
        }

        expectedContent = """
            var foo = require('../foo/foo.js');
        """

        transformTools.runTransform aliasifyWithConfig, jsFile, (err, result) ->
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

        content = """
            foo = require("foo");
        """
        expectedContent = """
            foo = require('#{jsFile.replace(/\\/gi, '\\\\')}');
        """

        transformTools.runTransform aliasifyWithConfig, jsFile, {content}, (err, result) ->
            return done err if err
            assert.equal result, expectedContent
            done()
