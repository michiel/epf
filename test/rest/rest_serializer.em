
describe 'Ep.RestSerializer', ->

  beforeEach ->
    @Serializer = Ep.RestSerializer.extend()
    @container = new Ember.Container()
    @container.register('serializer:main', @Serializer)
    @serializer = @container.lookup('serializer:main')


  context 'simple model', ->
    beforeEach ->
      @Post = Ep.Model.extend
        title: Ep.attr('string')
        longTitle: Ep.attr('string')
      @container.register 'model:post', @Post, instantiate: false


    describe 'deserialization', ->


      it 'reads plural hash key', ->
        data = {posts: {id: 1, title: 'wat', long_title: 'wat omgawd'}}
        models = @serializer.deserialize(data)
        post = models[0]
        expect(post).to.be.an.instanceof(@Post)
        expect(post.title).to.eq('wat')
        expect(post.longTitle).to.eq('wat omgawd')
        expect(post.id).to.eq("1")


      it 'reads singular hash key', ->
        data = {post: {id: 1, title: 'wat', long_title: 'wat omgawd'}}
        models = @serializer.deserialize(data)
        post = models[0]
        expect(post).to.be.an.instanceof(@Post)
        expect(post.title).to.eq('wat')
        expect(post.longTitle).to.eq('wat omgawd')
        expect(post.id).to.eq("1")


      it 'reads array value', ->
        data = {post: [{id: 1, title: 'wat', long_title: 'wat omgawd'}] }
        models = @serializer.deserialize(data)
        post = models[0]
        expect(post).to.be.an.instanceof(@Post)
        expect(post.title).to.eq('wat')
        expect(post.longTitle).to.eq('wat omgawd')
        expect(post.id).to.eq("1")


      it 'obeys mapped attributes', ->
        @serializer.map @Post,
          title: { key: 'POST_TITLE' }
        data = {post: {id: 1, POST_TITLE: 'wat', long_title: 'wat omgawd'}}
        models = @serializer.deserialize(data)
        post = models[0]
        expect(post).to.be.an.instanceof(@Post)
        expect(post.title).to.eq('wat')
        expect(post.longTitle).to.eq('wat omgawd')
        expect(post.id).to.eq("1")


      it 'reads null client_id as null', ->
        data = {posts: {client_id: null, id: 1, title: 'wat', long_title: 'wat omgawd'}}
        models = @serializer.deserialize(data)
        post = models[0]
        expect(post.clientId).to.be.null


    describe 'serialization', ->


      it 'serializes', ->
        post = @Post.create()
        post.id = 1
        post.clientId = "2"
        post.title = 'wat'
        post.longTitle = 'wat omgawd'
        data = @serializer.serialize(post, includeId: true)
        expect(data).to.eql({client_id: "2", id: 1, title: 'wat', long_title: 'wat omgawd'})


      it 'handles unloaded lazy model', ->
        lazyPost = Ep.LazyModel.create
          id: 1,
          clientId: "2"
          type: @Post
        data = @serializer.serialize(lazyPost, includeId: true)
        expect(data).to.eql client_id: "2", id: 1


      it 'handles loaded lazy model', ->
        post = @Post.create()
        post.id = 1
        post.clientId = "2"
        post.title = 'wat'
        post.longTitle = 'wat omgawd'
        lazyPost = Ep.LazyModel.create
          id: 1,
          type: @Post
        lazyPost.resolve(post)
        data = @serializer.serialize(lazyPost, includeId: true)
        expect(data).to.eql client_id: "2", id: 1, title: 'wat', long_title: 'wat omgawd'


      it 'obeys mapped attributes', ->
        @serializer.map @Post,
          title: { key: 'POST_TITLE' }
        post = @Post.create()
        post.id = 1
        post.clientId = "2"
        post.title = 'wat'
        post.longTitle = 'wat omgawd'
        data = @serializer.serialize(post, includeId: true)
        expect(data).to.eql({client_id: "2", id: 1, POST_TITLE: 'wat', long_title: 'wat omgawd'})


  context 'one->many', ->

    beforeEach ->
      @App = Ember.Namespace.create()
      class @Post extends Ep.Model
        title: Ep.attr('string')
      @App.Post = @Post

      class @Comment extends Ep.Model
        post: Ep.belongsTo(@Post)
      @App.Comment = @Comment

      @Post.reopen
        comments: Ep.hasMany(@Comment)

      @container.register 'model:post', @Post, instantiate: false
      @container.register 'model:comment', @Comment, instantiate: false


    it 'deserializes null hasMany', ->
      data = {post: [{id: 1, title: 'wat', comment_ids: null}] }
      models = @serializer.deserialize(data)
      post = models[0]
      expect(post.comments.length).to.eq(0)


    it 'deserializes null belongsTo', ->
      data = {comments: [{id: 1, title: 'wat', post_id: null}] }
      models = @serializer.deserialize(data)
      comment = models[0]
      expect(comment.post).to.be.null


  context 'one->many embedded', ->

    beforeEach ->
      @App = Ember.Namespace.create()
      class @Post extends Ep.Model
        title: Ep.attr('string')
      @App.Post = @Post

      class @Comment extends Ep.Model
        post: Ep.belongsTo(@Post)
      @App.Comment = @Comment

      @Post.reopen
        comments: Ep.hasMany(@Comment)

      @serializer.map @Post,
        comments: { embedded: 'always' }

      @container.register 'model:post', @Post, instantiate: false
      @container.register 'model:comment', @Comment, instantiate: false


    it 'deserializes null belongsTo', ->
      data = {comments: [{id: 1, title: 'wat', post: null}] }
      models = @serializer.deserialize(data)
      comment = models[0]
      expect(comment.post).to.be.null


  context 'one->one embedded', ->

    beforeEach ->
      @App = Ember.Namespace.create()
      class @Post extends Ep.Model
        title: Ep.attr('string')
      @App.Post = @Post

      class @User extends Ep.Model
        name: Ep.attr('string')
        post: Ep.belongsTo(@Post)
      @App.User = @User

      @Post.reopen
        user: Ep.belongsTo(@User)

      @serializer.map @Post,
        user: { embedded: 'always' }

      @container.register 'model:post', @Post, instantiate: false
      @container.register 'model:user', @User, instantiate: false


    it 'deserializes null belongsTo', ->
      data = {posts: [{id: 1, title: 'wat', user: null}] }
      models = @serializer.deserialize(data)
      post = models[0]
      expect(post.user).to.be.null