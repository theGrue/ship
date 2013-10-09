class Dropbox

  constructor: (@path) ->
    @name = 'Dropbox'
    @config =
      access_key: ''
      secret_key: ''

  deploy: (cb) ->
    console.log "deploying #{@path} to Dropbox"
    cb()

module.exports = Dropbox
