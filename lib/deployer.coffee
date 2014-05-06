path = require 'path'
readdirp = require 'readdirp'
W = require 'when'
_ = require 'lodash'

ConfigSchema = require './config-schema'

###*
 * The base class for all deployers to inherit from.
###
class Deployer
  ###*
   * Holds the schema that manages the configuration.
   * @type {ConfigSchema}
  ###
  configSchema: undefined

  ###*
   * The current configuration object for the deployer (prevents us from
     needing to pass configuration items around). This object may be mutated
     from what the configSchema defines after deployment starts.
   * @private
   * @type {Object}
  ###
  _config: undefined

  ###*
   * Set schema properties that all deployers use.
   * @extend
  ###
  constructor: ->
    # make sure these don't get shared between instances
    @configSchema = new ConfigSchema()
    @_config = {}

    @configSchema.schema.projectRoot =
      required: true
      default: './'
      type: 'string'
      description: 'The path to the root of the project to be shipped.'
    @configSchema.schema.sourceDir =
      required: true
      default: './public'
      type: 'string'
      description: ''
    @configSchema.schema.ignore =
      required: true
      default: ['ship*.opts']
      type: 'array'
      description: 'Minimatch-style strings for what files to ignore. This can be repeated to add multiple ignored patterns.'

  ###*
   * Run the deployment
   * @param {Object} config The configuration object for the deployer.
   * @return {Promise} Actually, only the extended functions return a promise.
     The base one doesn't because we need to call it with super
   * @extend
  ###
  deploy: (config) ->
    @_config = @configSchema.validate(config)
    @_config.sourceDir = path.normalize(@_config.sourceDir)
    @_config.projectRoot = path.normalize(@_config.projectRoot)

  ###*
   * Get the list of files to be deployed, taking into account the ignored
     files.
   * @param {Boolean} [invert=false] If true, return all the files that are
     not in supposed to be shipped.
   * @return {Promise} A promise for the array of filepaths to ship.
  ###
  getFileList: (invert = false) ->
    deferred = W.defer()
    ignored = @_config.ignore.map (v) -> "!#{v}"
    readdirp
      root: @_config.sourceDir
      fileFilter: ignored
      directoryFilter: ignored
      (err, res) =>
        if err then return deferred.reject err
        fileList = _.pluck(res.files, 'fullPath')
        unless invert
          deferred.resolve fileList
        else
          readdirp root: @_config.projectRoot, (err, res) ->
            if err then return deferred.reject err
            allProjectFiles = _.pluck(res.files, 'fullPath')
            deferred.resolve _.without(allProjectFiles, fileList...)

    return deferred.promise

module.exports = Deployer
