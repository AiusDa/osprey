express = require 'express'
path = require 'path'
osprey = require 'osprey'
https = require 'https'
fs = require 'fs'
path = require 'path'

app = express()

app.use express.json()
app.use express.urlencoded()
app.use express.logger('dev')

# WARNING: You have to create your own certificates
privateKey  = fs.readFileSync path.join(__dirname, '/assets/ssl/server.key'), 'utf8'
certificate = fs.readFileSync path.join(__dirname, '/assets/ssl/server.crt'), 'utf8'
credentials =
  key: privateKey
  cert: certificate
  passphrase: 'osprey'

api = osprey.create '/api', app,
  ramlFile: path.join(__dirname, '/assets/raml/api.raml'),
  logLevel: 'debug'

api.describe (api) ->
  api.get '/teams/:teamId', (req, res) ->
    res.send({ name: 'test' })

httpsServer = https.createServer credentials, app
httpsServer.listen 3000