_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class SimpleMeshbluMessageAs
  constructor: ({@meshbluConfig}) ->
    throw new Error 'SimpleMeshbluMessageAs: requires meshbluConfig' unless @meshbluConfig?
    @meshbluHttp = new MeshbluHttp @meshbluConfig

  send: ({message, as}, callback) =>
    return callback new Error 'SimpleMeshbluMessageAs: send requires message' unless message?
    return callback new Error 'SimpleMeshbluMessageAs: send requires as' unless as?
    @_generateToken as, (error, token) =>
      return callback error if error?
      meshbluConfig = @_generateMeshbluConfig { uuid: as, token }
      meshbluHttp = new MeshbluHttp meshbluConfig
      meshbluHttp.message message, (error) =>
        return callback error if error?
        @_revokeToken meshbluConfig, (error) =>
          console.error error if error?
          callback null

  sendWith: ({message, uuid, token}, callback)  =>
    return callback new Error 'SimpleMeshbluMessageAs: sendWith requires message' unless message?
    return callback new Error 'SimpleMeshbluMessageAs: sendWith requires uuid' unless uuid?
    return callback new Error 'SimpleMeshbluMessageAs: sendWith requires token' unless token?

    meshbluConfig = @_generateMeshbluConfig { uuid, token }
    meshbluHttp = new MeshbluHttp meshbluConfig
    meshbluHttp.message message, callback

  _generateMeshbluConfig: ({ uuid, token }) =>
    meshbluConfig = _.cloneDeep @meshbluConfig
    meshbluConfig.uuid = uuid
    meshbluConfig.token = token
    return meshbluConfig

  _generateToken: (uuid, callback) =>
    @meshbluHttp.generateAndStoreToken uuid, (error, result) =>
      return callback error if error?
      callback null, result.token

  _revokeToken: ({ uuid, token }, callback) =>
    @meshbluHttp.revokeToken uuid, token, callback


module.exports = SimpleMeshbluMessageAs
