{describe,beforeEach,afterEach,it,expect} = global
enableDestroy = require 'server-destroy'
shmock        = require '@octoblu/shmock'
SimpleMeshbluMessageAs     = require '../'

describe 'SimpleMeshbluMessageAs', ->
  beforeEach ->
    @meshblu = shmock()
    enableDestroy(@meshblu)
    @meshbluPort = @meshblu.address().port
    @sut = new SimpleMeshbluMessageAs {
      meshbluConfig:
        uuid: 'some-uuid'
        token: 'some-token'
        hostname: 'localhost'
        protocol: 'http'
        port: @meshbluPort
    }

  afterEach ->
    @meshblu.destroy()

  describe '->send', ->
    describe 'when called with a message and an as', ->
      beforeEach (done) ->
        userAuth = new Buffer('some-uuid:some-token').toString('base64')
        messageAuth = new Buffer('send-as-me:some-new-token').toString('base64')
        message =
          devices: ['*']
          topic: 'test'

        @generateToken = @meshblu.post '/devices/send-as-me/tokens'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 201, {
            token: 'some-new-token'
          }

        @sendMessage = @meshblu.post '/messages'
          .set 'Authorization', "Basic #{messageAuth}"
          .send message
          .reply 204

        @revokeToken = @meshblu.delete '/devices/send-as-me/tokens/some-new-token'
          .set 'Authorization', "Basic #{userAuth}"
          .reply 204

        @sut.send { message, as: 'send-as-me' }, done

      it 'should send the message', ->
        @sendMessage.done()

      it 'should generate a token', ->
        @generateToken.done()

      it 'should revoke the token', ->
        @revokeToken.done()

    describe 'when called without a message', ->
      beforeEach (done) ->
        @sut.send { as: 'send-as-me' }, (@error) =>
          done()

      it 'should have an error', ->
        expect(@error).to.exist
        expect(@error.message).to.equal 'SimpleMeshbluMessageAs: send requires message'

    describe 'when called without as', ->
      beforeEach (done) ->
        @sut.send { message: 'some-message', }, (@error) =>
          done()

      it 'should have an error', ->
        expect(@error).to.exist
        expect(@error.message).to.equal 'SimpleMeshbluMessageAs: send requires as'

  describe '->sendWith', ->
    describe 'when called with a message and a uuid / token', ->
      beforeEach (done) ->
        messageAuth = new Buffer('send-as-me:some-other-token').toString('base64')
        message =
          devices: ['*']
          topic: 'test'

        @sendMessage = @meshblu.post '/messages'
          .set 'Authorization', "Basic #{messageAuth}"
          .send message
          .reply 204

        @sut.sendWith { message, uuid: 'send-as-me', token: 'some-other-token' }, done

      it 'should send the message', ->
        @sendMessage.done()

    describe 'when called without a message', ->
      beforeEach (done) ->
        @sut.sendWith { uuid: 'send-as-me', token: 'some-other-token' }, (@error) =>
          done()

      it 'should have an error', ->
        expect(@error).to.exist
        expect(@error.message).to.equal 'SimpleMeshbluMessageAs: sendWith requires message'

    describe 'when called without uuid', ->
      beforeEach (done) ->
        @sut.sendWith { message: 'some-message', token: 'some-other-token' }, (@error) =>
          done()

      it 'should have an error', ->
        expect(@error).to.exist
        expect(@error.message).to.equal 'SimpleMeshbluMessageAs: sendWith requires uuid'

    describe 'when called without token', ->
      beforeEach (done) ->
        @sut.sendWith { message: 'some-message', uuid: 'send-as-me' }, (@error) =>
          done()

      it 'should have an error', ->
        expect(@error).to.exist
        expect(@error.message).to.equal 'SimpleMeshbluMessageAs: sendWith requires token'
