UriTemplateReader = require './uri-template-reader'
parser = require './wrapper'
ApiKit = require './apikit'
ValidationError = require './exceptions/validation-error'

exports.register = (apiPath, context, settings) =>
  @apikit = new ApiKit(apiPath, context, settings)
  @apikit.register()

exports.route = (apiPath, context, settings) ->
  @apikit = new ApiKit(apiPath, context, settings)
  @apikit.route settings.enableMocks

exports.validations = (apiPath, context, settings) ->
  @apikit = new ApiKit(apiPath, context, settings)
  @apikit.validations()

exports.exceptionHandler = (settings) ->
  (err, req, res, next) ->
    console.log settings[typeof err]
    console.log 'test1'
    console.log err
    if err instanceof ValidationError
      console.log err
      res.send 400
    else
      next()

exports.get = (uriTemplate, handler) =>
  @apikit.get uriTemplate, handler

exports.post = (uriTemplate, handler) =>
  @apikit.post uriTemplate, handler

exports.put = (uriTemplate, handler) =>
  @apikit.put uriTemplate, handler

exports.delete = (uriTemplate, handler) =>
  @apikit.delete uriTemplate, handler

exports.patch = (uriTemplate, handler) =>
  @apikit.patch uriTemplate, handler

exports.head = (uriTemplate, handler) =>
  @apikit.head uriTemplate, handler