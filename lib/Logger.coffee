Bunyan = require 'bunyan'

pkg = require '../package.json'


module.exports = class Logger extends Bunyan
  constructor: (component) ->
    super {name: pkg.name, component}
