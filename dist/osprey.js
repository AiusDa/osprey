(function() {
  var Osprey, Validation, errorDefaultSettings, express, logger, path,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  express = require('express');

  path = require('path');

  Validation = require('./validation');

  logger = require('./utils/logger');

  errorDefaultSettings = require('./error-default-settings');

  Osprey = (function() {
    Osprey.prototype.handlers = [];

    function Osprey(apiPath, context, settings) {
      this.apiPath = apiPath;
      this.context = context;
      this.settings = settings;
      this.patch = __bind(this.patch, this);
      this.head = __bind(this.head, this);
      this["delete"] = __bind(this["delete"], this);
      this.put = __bind(this.put, this);
      this.post = __bind(this.post, this);
      this.get = __bind(this.get, this);
      this.validations = __bind(this.validations, this);
      this.route = __bind(this.route, this);
      this.init = __bind(this.init, this);
      this.register = __bind(this.register, this);
    }

    Osprey.prototype.register = function(router, uriTemplateReader, resources) {
      if (this.settings.enableValidations == null) {
        this.settings.enableValidations = true;
      }
      if (this.settings.enableValidations) {
        this.context.use(this.validations(uriTemplateReader, resources));
      }
      this.context.use(this.exceptionHandler(this.settings.exceptionHandler));
      return this.context.use(this.route(router, this.settings.enableMocks));
    };

    Osprey.prototype.registerConsole = function() {
      if (this.settings.enableConsole == null) {
        this.settings.enableConsole = true;
      }
      if (this.settings.enableConsole) {
        this.context.use("" + this.apiPath + "/console", express["static"](path.join(__dirname, '/assets/console')));
        this.context.get(this.apiPath, this.ramlHandler(this.settings.ramlFile));
        return logger.info('Osprey::APIConsole has been initialized successfully');
      }
    };

    Osprey.prototype.ramlHandler = function(ramlPath) {
      return function(req, res) {
        if (req.accepts('application/raml+yaml') != null) {
          return res.sendfile(ramlPath);
        } else {
          return res.send(406);
        }
      };
    };

    Osprey.prototype.init = function(router) {
      var handler, _i, _len, _ref, _results;
      _ref = this.handlers;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        handler = _ref[_i];
        _results.push(router.resolveMethod(handler));
      }
      return _results;
    };

    Osprey.prototype.route = function(router, enableMocks) {
      var _this = this;
      logger.info('Osprey::Router has been initialized successfully');
      return function(req, res, next) {
        if (req.path.indexOf(_this.apiPath) >= 0) {
          return router.resolveMock(req, res, next, _this.settings.enableMocks);
        } else {
          return next();
        }
      };
    };

    Osprey.prototype.exceptionHandler = function(settings) {
      var key, value;
      logger.info('Osprey::ExceptionHandler has been initialized successfully');
      for (key in settings) {
        value = settings[key];
        errorDefaultSettings[key] = value;
      }
      return function(err, req, res, next) {
        var errorHandler;
        errorHandler = errorDefaultSettings[err.constructor.name];
        if (errorHandler != null) {
          return errorHandler(err, req, res, next);
        } else {
          return next();
        }
      };
    };

    Osprey.prototype.validations = function(uriTemplateReader, resources) {
      var _this = this;
      logger.info('Osprey::Validations has been initialized successfully');
      return function(req, res, next) {
        var regex, resource, template, uri, urlPath, validation;
        regex = new RegExp("^\\" + _this.apiPath + "(.*)");
        urlPath = regex.exec(req.url);
        if (urlPath && urlPath.length > 1) {
          uri = urlPath[1].split('?')[0];
          template = uriTemplateReader.getTemplateFor(uri);
          if (template != null) {
            resource = resources[template.uriTemplate];
            if (resource != null) {
              validation = new Validation(req, uriTemplateReader, resource, _this.apiPath);
              validation.validate();
            }
          }
        }
        return next();
      };
    };

    Osprey.prototype.get = function(uriTemplate, handler) {
      return this.handlers.push({
        method: 'get',
        template: uriTemplate,
        handler: handler
      });
    };

    Osprey.prototype.post = function(uriTemplate, handler) {
      return this.handlers.push({
        method: 'post',
        template: uriTemplate,
        handler: handler
      });
    };

    Osprey.prototype.put = function(uriTemplate, handler) {
      return this.handlers.push({
        method: 'put',
        template: uriTemplate,
        handler: handler
      });
    };

    Osprey.prototype["delete"] = function(uriTemplate, handler) {
      return this.handlers.push({
        method: 'delete',
        template: uriTemplate,
        handler: handler
      });
    };

    Osprey.prototype.head = function(uriTemplate, handler) {
      return this.handlers.push({
        method: 'head',
        template: uriTemplate,
        handler: handler
      });
    };

    Osprey.prototype.patch = function(uriTemplate, handler) {
      return this.handlers.push({
        method: 'patch',
        template: uriTemplate,
        handler: handler
      });
    };

    return Osprey;

  })();

  module.exports = Osprey;

}).call(this);
