HttpUtils = require '../utils/http-utils'
OspreyBase = require '../utils/base'
logger = require '../utils/logger'

class MockDeleteHandler extends HttpUtils
  resolve: (req, res, methodInfo) ->
    logger.debug "Mock resolved - DELETE #{req.url}"
    res.send @readStatusCode(methodInfo)

class DeleteHandler extends OspreyBase
  constructor: (@apiPath, @context, @resources) ->

  resolve: (uriTemplate, handler) =>
    template = "#{@apiPath}#{uriTemplate}"
    
    @context.delete template, (req, res) ->
      handler req, res

exports.MockHandler = MockDeleteHandler
exports.Handler = DeleteHandler
