express = require 'express'
path = require 'path'
osprey = require 'osprey'

app = express()

app.use express.bodyParser()

api = osprey.create '/api', app,
  ramlFile: path.join(__dirname, 'api.raml')
  enableMocks: true
  enableValidations: false
  enableConsole: false
  logLevel: 'off'

module.exports = app