express = require 'express'
path = require 'path'
Validation = require './validation'
logger = require './utils/logger'

class Osprey
  handlers: []

  constructor: (@apiPath, @context, @settings) ->

  register: (router, uriTemplateReader, resources) =>
    @settings.enableValidations = true unless @settings.enableValidations?
    @settings.enableConsole = true unless @settings.enableConsole?

    if @settings.enableValidations
      @context.use @validations(uriTemplateReader, resources)
      logger.info 'Validations has been initialized successfully'

    @context.use @route(router, @settings.enableMocks)
    logger.info 'RAML router has been initialized successfully'

    if @settings.enableConsole
      @context.use "#{@apiPath}/console", express.static(path.join(__dirname, '/assets/console'))
      @context.get @apiPath, @ramlHandler(@settings.ramlFile)
      logger.info 'API console has been initialized successfully'

  ramlHandler: (ramlPath) ->
    return (req, res) ->
      if req.accepts('application/raml+yaml')?
        res.sendfile ramlPath
      else
        res.send 406

  init: (router) =>
    for handler in @handlers
      router.resolveMethod handler

  route: (router, enableMocks) =>
    logger.info 'RAML router has been initialized successfully'
    (req, res, next) =>
      if req.path.indexOf(@apiPath) >= 0
        router.resolveMock req, res, next, @settings.enableMocks
      else
        next()

  validations: (uriTemplateReader, resources) =>
    logger.info 'Validations has been initialized successfully'
    (req, res, next) =>
      regex = new RegExp "^\\" + @apiPath + "(.*)"
      urlPath = regex.exec req.url

      if urlPath and urlPath.length > 1
        uri = urlPath[1].split('?')[0]
        template = uriTemplateReader.getTemplateFor(uri)

        if template?
          resource = resources[template.uriTemplate]

          if resource?
            validation = new Validation req, uriTemplateReader, resource, @apiPath
            if req.path.indexOf(@apiPath) >= 0 and not validation.isValid()
              res.send 400
              return

      next()

  get: (uriTemplate, handler) =>
    @handlers.push { method: 'get', template: uriTemplate, handler: handler }

  post: (uriTemplate, handler) =>
    @handlers.push { method: 'post', template: uriTemplate, handler: handler }

  put: (uriTemplate, handler) =>
    @handlers.push { method: 'put', template: uriTemplate, handler: handler }

  delete: (uriTemplate, handler) =>
    @handlers.push { method: 'delete', template: uriTemplate, handler: handler }

  head: (uriTemplate, handler) =>
    @handlers.push { method: 'head', template: uriTemplate, handler: handler }

  patch: (uriTemplate, handler) =>
    @handlers.push { method: 'patch', template: uriTemplate, handler: handler }

module.exports = Osprey