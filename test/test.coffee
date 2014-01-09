path = require 'path'
assert = require 'assert'
transformTools = require 'browserify-transform-tools'

aliasify = require '../src/aliasify'

describe "aliasify", ->
    it "should correctly transform a file", (done) ->
        jsFile = path.resolve __dirname, "../testFixtures/test/src/index.js"
        transformTools.runTransform aliasify, jsFile, (err, result) ->
            return done err if err
            assert.equal result, """
                d3 = require('./../shims/d3.js');
                _ = require('lodash');
            """
            done()

    it "should correctly transform a file when the configuration is in a different directory", (done) ->
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

