express = require 'express'
_ = require 'lodash'

server = express()

# wrap the express server with a simple http one
# and add socket.io to it
httpServer = require('http').createServer(server)
io = require('socket.io').listen(httpServer)

io.set('log level', 1) # warn
io.of('/livereload').on 'connection', (socket) ->
  console.log "new client connected"

# reload the client if a css file is changed in css/
# or if a .js or .ejs file is changed in src
watch = require 'node-watch'
console.log "watching js and css files"
filterWatch = (pattern, fn) ->
  return (filename) -> fn(filename) if pattern.test(filename)

watch(['.'], filterWatch(/\.js$|\.css$|\.html$/i, _.debounce((filename) ->
  console.log "file changed: #{filename}"
  io.of('/livereload').emit 'reload'
, 200)))


# super basic logging, more a sanity test
server.use (req, res, next) ->
  console.log "#{new Date()} \t #{req.method} at #{req.url}"
  next()


server.on 'error', (err) ->
  console.log "server error !"
  console.log err

# serve static files
server.use(express.directory(__dirname))
server.use(express.static(__dirname))

# server.listen(port)
httpServer.listen(9000)
console.log "Listening on port 9000"
