WebSocketServer = require('ws').Server
fs = require 'fs'

# fetchPage = (path, done) ->
#   text = fs.readFile path, 'utf8', (err, text) ->
#     return console.log ['linkmap fetchPage error', path, err] if err
#     done JSON.parse text

# findLinks = (page) ->
# 	unique = {}
# 	for item in page.story || []
# 		links = switch item?.type
# 			when 'paragraph' then item.text.match /\[\[([^\]]+)\]\]/g
# 		if links
# 			for link in links
# 				[match, title] = link.match /\[\[([^\]]+)\]\]/
# 				unique[asSlug title] = title
# 	slug for slug, title of unique

# buildmap = (pages) ->
# 	fs.readdir pages, (err, names) ->
# 		return if err or !names?.length
# 		for slug in names
# 			if slug.match /^[a-z0-9-]+$/
# 				do (slug) ->
# 					fetchPage "#{pages}/#{slug}", (page) ->
# 						linkmap[slug] = findLinks page
	
fs = require 'fs'
tz = null


startServer = (params) ->

	console.log 'txtzyme startServer', (k for k,v of params)
	fn = '/dev/cu.usbmodem12341'
	fs.open fn, 'r+', (err, fd) ->
		console.log 'txtzyme open error: ', err if err
		tz = {fd, fn}
		console.log tz

		readbuf = new Buffer 128
		copybuf = new Buffer 128
		read = (remains) ->
			fs.read tz.fd, readbuf, remains, readbuf.length-remains, null, (err, bytesRead, buffer) ->
				console.log 'txtzyme read err ', err if err
				have = bytesRead + remains
				for i in [have-1..0]
					if buffer[i] is 10
						take = buffer.toString 'ascii', 0, (tail = i+1)
						console.log take
						remains = have - tail
						if remains
							buffer.copy copybuf, 0, tail, have
							copybuf.copy readbuf, 0, 0, remains
						return read remains
				read have
		read 0


	server = new WebSocketServer({server: params.server, path: '/plugin/txtzyme'})

	server.on 'connection', (socket) ->
		console.log 'connection established, listening'

		socket.on 'message', (message) ->
			buf = new Buffer "#{message}\n", 'utf8'
			fs.write tz.fd, buf, 0, buf.length, -1, (err, written, buffer) ->
				console.log 'txtzyme write error: ', err if err
				fs.fsync tz.fd


		# ws.send JSON.stringify(linkmap, null, 2), (err) ->
		# 	console.log 'unable to send ws message:', err if err

module.exports = {startServer}
