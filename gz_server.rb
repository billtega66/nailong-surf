#!/usr/bin/ruby
# Static file server with gzip for the game (big win over slow tunnels).
require 'webrick'
require 'zlib'

root = File.dirname(__FILE__)
server = WEBrick::HTTPServer.new(
  Port: 8765,
  BindAddress: '127.0.0.1',
  DocumentRoot: root,
  AccessLog: [],
  Logger: WEBrick::Log.new(File::NULL)
)

# compress text responses when the client accepts gzip
require 'stringio'
server.mount_proc '/' do |req, res|
  path = req.path == '/' ? '/index.html' : req.path
  file = File.join(root, WEBrick::HTTPUtils::escape_path(path))
  file = File.expand_path(file)
  unless file.start_with?(root) && File.file?(file)
    res.status = 404
    res.body = 'not found'
    next
  end
  body = File.binread(file)
  type = WEBrick::HTTPUtils::mime_type(file, WEBrick::HTTPUtils::DefaultMimeTypes)
  if body.bytesize > 1024 && req['accept-Encoding'].to_s.include?('gzip') &&
     %w[text/html text/javascript application/javascript text/css application/json].include?(type)
    res['Content-Encoding'] = 'gzip'
    gz = Zlib::GzipWriter.new(StringIO.new, Zlib::BEST_COMPRESSION)
    gz.write(body)
    res.body = gz.close.string
  else
    res.body = body
  end
  res['Content-Type'] = type
  res['Cache-Control'] = 'no-cache'
end

trap('INT') { server.shutdown }
server.start
