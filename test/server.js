/* global describe, beforeEach, it */

var expect = require('chai').expect
var popsicle = require('popsicle')
var server = require('popsicle-server')
var router = require('osprey-router')
var join = require('path').join
var osprey = require('../')
var utils = require('./support/utils')

var EXAMPLE_RAML_PATH = join(__dirname, 'fixtures/example.raml')

var success = utils.response('success')

describe('server', function () {
  var http

  beforeEach(function () {
    return osprey.loadFile(EXAMPLE_RAML_PATH, { server: { cors: true, compression: true } })
      .then(function (middleware) {
        var app = router()

        app.use(middleware)

        app.get('/users', success)
        app.get('/unknown', success)

        http = utils.createServer(app)
      })
  })

  it('should accept defined routes', function () {
    return popsicle('/users')
      .use(server(http))
      .then(function (res) {
        expect(res.body).to.equal('success')
        expect(res.status).to.equal(200)
      })
  })

  it('should reject undefined routes', function () {
    return popsicle('/unknown')
      .use(server(http))
      .then(function (res) {
        expect(res.status).to.equal(404)
      })
  })

  it('should have cors enabled', function () {
    return popsicle.options('/users')
      .use(server(http))
      .then(function (res) {
        expect(res.status).to.equal(204)
        expect(res.headers['access-control-allow-origin']).to.equal('*')
        expect(res.headers['access-control-allow-methods']).to.equal('GET,HEAD,PUT,PATCH,POST,DELETE')
      })
  })

  it('should have compression enabled', function () {
    return popsicle('/users')
      .use(server(http))
      .then(function (res) {
        expect(res.body).to.equal('success')
        expect(res.headers['content-encoding']).to.equal('gzip')
      })
  })
})
