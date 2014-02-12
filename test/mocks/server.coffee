class ExpressMock
  constructor: ->
    @middlewares = []
    @routes = {}
    @getMethods = []
    @postMethods = []
    @putMethods = []
    @deleteMethods = []
    @headMethods = []
    @patchMethods = []
    
  use: (content) =>
    @middlewares.push content

  get: (content) =>
    @getMethods.push content

  post: (content) =>
    @postMethods.push content

  put: (content) =>
    @putMethods.push content

  delete: (content) =>
    @deleteMethods.push content

  head: (content) =>
    @headMethods.push content

  patch: (content) =>
    @patchMethods.push content

class ResponseMock
  constructor: ->
    @response = null
  send: (context) ->
    @response = context
  set: (key, value) ->
    @key = key
    @value = value

class RequestMock
  constructor: (@method, @url) ->
  accepts: (mimetype) ->
    true

class MiddlewareMock
  nextCounter: 0
  next: () =>
    @nextCounter = @nextCounter + 1

exports.express = ExpressMock
exports.response = ResponseMock
exports.request = RequestMock
exports.middleware = MiddlewareMock