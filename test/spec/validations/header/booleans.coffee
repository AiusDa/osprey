parser = require '../../../../src/wrapper'
Validation = require '../../../../src/validation'
should = require 'should'
Request = require('../../../mocks/server').request
Logger = require '../../../mocks/logger'
UriTemplateReader = require '../../../../src/uri-template-reader'

describe 'OSPREY VALIDATIONS - HEADER - TYPE - BOOLEAN', =>
  before (done) =>
    parser.loadRaml "./test/assets/validations.header.raml", new Logger, (wrapper) =>
      @resources = wrapper.getResources()
      templates = wrapper.getUriTemplates()
      @uriTemplateReader = new UriTemplateReader templates
  
      done()

  it 'Should throw an exception if the value type is incorrect', (done) =>
    # Arrange
    resource = @resources['/boolean']
    req = new Request 'GET', '/api/boolean'
    validation = new Validation req, @uriTemplateReader, resource, '/api'

    req.addHeader 'content-type', 'application/json'
    req.addHeader 'Header', 'aa'

    # Assert
    ( ->
      validation.validate()
    ).should.throw();

    done()

  it 'Should be correctly validated if the type is valid', (done) =>
    # Arrange
    resource = @resources['/boolean']
    req = new Request 'GET', '/api/boolean/'
    validation = new Validation req, @uriTemplateReader, resource, '/api'

    req.addHeader 'content-type', 'application/json'
    req.addHeader 'Header', 'true'

    # Assert
    ( ->
      validation.validate()
    ).should.not.throw();

    done()          

  it 'Should be correctly validated if the parameter is present', (done) =>
    # Arrange
    resource = @resources['/boolean']
    req = new Request 'GET', '/api/boolean'
    validation = new Validation req, @uriTemplateReader, resource, '/api'

    req.addHeader 'Header', 'true'

    # Assert
    ( ->
      validation.validate()
    ).should.not.throw();

    done()

  it 'Should throw an exception if the parameter is not present', (done) =>
    # Arrange
    resource = @resources['/boolean']
    req = new Request 'GET', '/api/boolean'
    validation = new Validation req, @uriTemplateReader, resource, '/api'

    # Assert
    ( ->
      validation.validate()
    ).should.throw();

    done()  