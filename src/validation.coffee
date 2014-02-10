SchemaValidator = require('jsonschema').Validator
OspreyBase = require './utils/base'
logger = require './utils/logger'
InvalidUriParameterError = require './errors/invalid-uri-parameter-error'
InvalidFormParameterError = require './errors/invalid-form-parameter-error'
InvalidQueryParameterError = require './errors/invalid-query-parameter-error'
InvalidHeaderError = require './errors/invalid-header-error'
InvalidBodyError = require './errors/invalid-body-error'

class Validation
  constructor: (@req, @uriTemplateReader, @resource, @apiPath) ->

  validate: () =>
    method = @getMethod()

    @validateUriParams()

    if method?
      @validateQueryParams method

      #TODO: Fix headers validation. Currently is not working due to the headers are being defined under the http status code
      @validateHeaders method
      
      @validateFormParams method

      unless @validateSchema method
        #TODO: Add schema error context!
        throw new InvalidBodyError {}

  isForm: () =>
    @req.headers['content-type'] in ['application/x-www-form-urlencoded', 'multipart/form-data']

  isJson: () =>
    # TODO: Fixme. If any content-type is defined it should be defaulted to the first content-type defined in the raml file
    @req.headers['content-type'] == 'application/json' or @req.headers['content-type'].endsWith '+json'

  validateSchema: (@method) =>
    if method.body? and @isJson()
      contentType =  method.body[@req.headers['content-type']]
      if contentType? and contentType.schema?
        schemaValidator = new SchemaValidator()
        return not (schemaValidator.validate @req.body, JSON.parse contentType.schema).errors.length
    true

  getMethod: () =>
    if @resource.methods?
      for method in @resource.methods
        if method.method == @req.method.toLowerCase()
          return method

    return null

  readValidationInfo: (key, value, validationDescriptor) ->
    delete validationDescriptor.description
    delete validationDescriptor.displayName
    delete validationDescriptor.example

    validationInfo =
      parameter: key
      value: value
      validationRule: validationDescriptor

    validationInfo

  validateUriParams: () =>
    if @resource.uriParameters?
      uri = @req.url.replace @apiPath, ''

      reqUriParameters = @uriTemplateReader.getUriParametersFor uri

      for key, ramlUriParameter of @resource.uriParameters
        if not @isValid reqUriParameters[key], ramlUriParameter
          logger.error "Invalid URI Parameter :#{key} - Request: #{@req.url}, Parameter value: #{reqUriParameters[key]}"
          logger.data "Validation rule", ramlUriParameter
          throw new InvalidUriParameterError @readValidationInfo(key, reqUriParameters[key], ramlUriParameter)

  validateFormParams: (method) =>
    if @isForm()
      for key, ramlFormParameter of method.body.formParameters
        reqFormParam = @req.body[key]
        if not @isValid reqFormParam, ramlFormParameter
          logger.error "Invalid Form Parameter :#{key} - Request: #{@req.url}, Parameter value: #{reqFormParam}"
          logger.data "Validation Info", ramlFormParameter
          throw new InvalidFormParameterError @readValidationInfo(key, reqFormParam, ramlFormParameter)

  validateQueryParams: (method) =>
    if method.queryParameters?
      for key, ramlQueryParameter of method.queryParameters
        reqQueryParam = @req.query[key]
        if not @isValid reqQueryParam, ramlQueryParameter
          logger.error "Invalid Query Parameter :#{key} - Request: #{@req.url}, Parameter value: #{reqQueryParam}"
          logger.data "Validation Info", ramlQueryParameter
          throw new InvalidQueryParameterError @readValidationInfo(key, reqQueryParam, ramlQueryParameter)

  validateHeaders: (method) =>
    if method.headers?
      for key, ramlHeader of method.headers
        reqHeader = @req.headers[key]
        if not @isValid reqHeader, ramlHeader
          logger.error "Invalid Header :#{key} - Request: #{@req.url}, Header value: #{reqHeader}"
          logger.data "Validation Info", ramlHeader
          throw new InvalidHeaderError @readValidationInfo(key, reqHeader, ramlHeader)

  isValid: (@reqParam, @ramlParam) =>
    (@validateRequired reqParam, ramlParam) and (@validateType reqParam, ramlParam)

  validateRequired: (@reqParam, @ramlParam) =>
    not ramlParam.required or reqParam?

  validateType: (@reqParam, @ramlParam) =>
    if 'string' == ramlParam.type
      @validateString reqParam, ramlParam
    else if 'number' == ramlParam.type
      @validateNumber reqParam, ramlParam
    else if 'integer' == ramlParam.type
      @validateInt reqParam, ramlParam
    else if 'boolean' == ramlParam.type
      @validateBoolean reqParam
    else
      true

  validateString: (@reqParam, @ramlParam) =>
    if ramlParam.pattern? and reqParam.match(ramlParam.pattern)
      return false
    if ramlParam.minLength? and reqParam.length < ramlParam.minLength
      return false
    if ramlParam.maxLength? and reqParam.length > ramlParam.maxLength
      return false
    if ramlParam.enumeration? and not ramlParam.enumeration in ramlParam.enumeration
      return false
    true

  validateNumber: (@reqParam, @ramlParam) =>
    try number = parseFloat reqParam
    catch e then false
    if ramlParam.minimum? and number < ramlParam.minimum
      return false
    if ramlParam.maximum? and number > ramlParam.maximum
      return false
    true

  validateInt: (@reqParam, @ramlParam) =>
    try number = parseInt reqParam
    catch e then false
    if ramlParam.minimum? and number < ramlParam.minimum
      return false
    if ramlParam.maximum? and number > ramlParam.maximum
      return false
    true

  validateBoolean: (@reqParam) =>
    "true" == reqParam or "false" == reqParam

module.exports = Validation
