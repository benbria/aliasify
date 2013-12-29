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
