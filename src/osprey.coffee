UriTemplateReader = require './uri-template-reader'
OspreyRouter = require './router'
parser = require './wrapper'
express = require 'express'
path = require 'path'
Validation = require './validation'

class Osprey
  constructor: (@apiPath, @context, @settings) ->

  register: =>
    @settings.enableConsole = true unless @settings.enableConsole?
    @settings.enableValidations = true unless @settings.enableValidations?

    if @settings.enableValidations
      @context.use @validations()

    @context.use @route(@settings.enableMocks)

    if @settings.enableConsole
      @context.use "#{@apiPath}/console", express.static(path.join(__dirname, '/assets/console'))
      @context.get @apiPath, @ramlHandler(@settings.ramlFile)

    if @settings.exceptionHandler
      @context.use @exceptionHandler(@settings.exceptionHandler)

  ramlHandler: (ramlPath) ->
    return (req, res) ->
      if req.accepts('application/raml+yaml')?
        res.sendfile ramlPath
      else
        res.send 406

  route: (enableMocks) =>
    (req, res, next) =>
      if req.path.indexOf(@apiPath) >= 0
        @readRaml (router) =>
          router.resolveMock req, res, next, @settings.enableMocks
      else
        next()

  exceptionHandler: (settings) ->
    (err, req, res, next) ->
      errorHandler = settings[err.constructor.name]
      
      if errorHandler?
        errorHandler err, req, res
      else
        next()

  # TODO: refactor
  validations: () =>
    (req, res, next) =>
      @readRaml (router, uriTemplateReader, resources) =>
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
    @readRaml (router) ->
      router.resolveMethod 'get', uriTemplate, handler

  post: (uriTemplate, handler) =>
    @readRaml (router) ->
      router.resolveMethod 'post', uriTemplate, handler

  put: (uriTemplate, handler) =>
    @readRaml (router) ->
      router.resolveMethod 'put', uriTemplate, handler

  delete: (uriTemplate, handler) =>
    @readRaml (router) ->
      router.resolveMethod 'delete', uriTemplate, handler

  head: (uriTemplate, handler) =>
    @readRaml (router) ->
      router.resolveMethod 'head', uriTemplate, handler

  patch: (uriTemplate, handler) =>
    @readRaml (router) ->
      router.resolveMethod 'patch', uriTemplate, handler

  readRaml: (callback) =>
    parser.loadRaml @settings.ramlFile, (wrapper) =>
      resources = wrapper.getResources()
      templates = wrapper.getUriTemplates()
      uriTemplateReader = new UriTemplateReader templates
      router = new OspreyRouter @apiPath, @context, resources, uriTemplateReader

      callback router, uriTemplateReader, resources

module.exports = Osprey
