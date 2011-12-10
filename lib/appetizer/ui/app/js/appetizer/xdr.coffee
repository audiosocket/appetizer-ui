# IE XDomainRequest support. Oh how I hate it.

statii =
  200: "OK"
  201: "CREATED"
  202: "ACCEPTED"
  204: "NO CONTENT"
  401: "UNAUTHORIZED"
  403: "FORBIDDEN"
  404: "NOT FOUND"
  409: "CONFLICT"
  422: "PRECONDITION FAILED"
  500: "INTERNAL SERVER ERROR"

Appetizer.transportXDR = (settings, original, xhr) ->
  xdr   = new XDomainRequest
  sep   = if settings.url.indexOf("?") is -1 then "?" else "&"
  url   = [settings.url, "xdr"].join sep

  xdr.open "POST", url

  abort: ->
    xdr.abort()

  send: (headers, complete) ->
    xdr.onerror = ->
      console.log "FIX: xdr onerror"

    xdr.onload = ->
      [status, headers, body] = $.parseJSON xdr.responseText

      description = statii[status] or "UNKNOWN"
      responses   = text: body

      complete status, description, responses, headers

    xdr.onprogress = ->

      # HACK: I wasn't able to get multiple requests to work (only
      # the first one would ever trigger `onload`) until I assigned
      # this empty handler to `onprogress`. What the actual fuck.

    xdr.ontimeout = ->
      console.log "FIX: xdr ontimeout"

    xdr.send JSON.stringify [settings.type, headers, settings.data]
