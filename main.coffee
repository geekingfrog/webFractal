# some variables

# fullscreen
canvas = document.querySelector("canvas")
canvas.width = window.innerWidth - window.innerWidth%2
canvas.height = window.innerHeight - window.innerHeight%2


xmax0 =  1
xmin0 = -3
ymin0 = -1
ymax0 = ymin0 + (xmax0-xmin0)/(canvas.width/canvas.height)
window.zoomFactor = 1

canvas = document.getElementById("fractal")
ctx = canvas.getContext("2d")
ctx.fillStyle = "#000"
ctx.fillRect(0,0,canvas.width, canvas.height)

# all job started before this date are moot and their result will be discarded
cancelDate = 0

# create workers
nbrWorker = 5
idleWorkers = []
jobQueue = []
workingWorkers = {}
for i in [0...nbrWorker]
  worker = new Worker("fractalWorker.js")
  idleWorkers.push worker
  worker.addEventListener("message", (e) ->
    if e.data.queueDate > cancelDate
      ctx.putImageData(e.data.img, e.data.px0, e.data.py0)
      idleWorkers.push this # put the worker back in the queue
      delete workingWorkers[e.data.workerId]
    processJobs()
    return
  )

warmPalette = window.palettes.generateWarmPalette(20)
palette = window.palettes.generatePalette(50)

jobSorted = false
# add a rendering job
addJob = (data) ->
  jobData = {
    imgData: ctx.createImageData(data.width, data.height)
    pxWidth: data.width
    pxHeight: data.height
    xmin: data.xmin
    xmax: data.xmax
    ymin: data.ymin
    ymax: data.ymax
    limit: data.limit
    px0: data.px0
    py0: data.py0
    queueDate: Date.now()
    palette: palette
  }
  jobQueue.push jobData
  jobSorted = false


processJobs = ->
  unless jobSorted
    distCenter = (x, y) ->
      return Math.abs(x-canvas.width/2)*Math.abs(x-canvas.width/2)+Math.abs(y-canvas.height/2)*Math.abs(y-canvas.height/2)

    jobQueue.sort (a, b) ->
      da = distCenter(a.px0, a.py0)
      db = distCenter(b.px0, b.py0)

      return da - db
    jobSorted = true


  while jobQueue.length and idleWorkers.length
    worker = idleWorkers.pop()
    job = jobQueue.shift()
    workingWorkers[job.queueDate] = worker
    worker.postMessage(job)

cancelJobs = ->
  cancelDate = Date.now() - 1
  jobQueue.length = 0
  for start, worker of workingWorkers
    idleWorkers.push worker
  workingWorkers = {}
  return

# limit if a function of the zoomfactor
computeLimit = (zoom) ->
  if zoom < 1
    zoom = 1
  return 100 + zoom*50

# take a rectangle as an input and create
# tiles from it to be rendered by different workers
# no clipping handling for the moment, assume parameters are correct and
# in range
window.sliceRenderer = (px, py, width, height, xmin, xmax, ymin, ymax, limit = computeLimit(zoomFactor)) ->
  console.log "calling sliceRenderer with args: ", arguments
  tileW = 200
  tileH = 200
  nbrXTiles = width/tileW
  nbrYTiles = height/tileH

  xWidth = xmax - xmin
  yHeight = ymax - ymin

  stepX = xWidth*tileW/width
  stepY = yHeight*tileH/height

  i = 0
  while i < nbrXTiles
    jobXmin = xmin + i*stepX
    jobXmax = Math.min(jobXmin+stepX, xmax)
    jobPx0 = px + i*tileW
    if (i+1)*tileW > width
      jobWidth = width - i*tileW
    else
      jobWidth = tileW

    j = 0
    while j < nbrYTiles
      jobYmin = ymin + j*stepY
      jobYmax = Math.min(jobYmin+stepY, ymax)
      jobPy0 = py + j*tileH
      if (j+1)*tileH > height
        jobHeight = height - j*tileH
      else
        jobHeight = tileH

      jobData = {
        px0: jobPx0
        width: jobWidth
        py0: jobPy0
        height: jobHeight
        xmin: jobXmin
        xmax: jobXmax
        ymin: jobYmin
        ymax: jobYmax
        limit: limit
      }
      addJob(jobData)

      j++

    i++

  processJobs()

  return

################################################################################ 
# drag&drop part
################################################################################ 
isDragging = false
startDragX = startDragY = null
snapshot = null

startDrag = (ev) ->
  console.log "start dragging"
  isDragging = true
  startDragX = ev.x or ev.clientX
  startDragY = ev.y or ev.clientY
  snapshot = ctx.getImageData(0, 0, canvas.width, canvas.height)
  canvas.addEventListener("mousemove", dragImage)

stopDrag = (ev) ->
  x = ev.x or ev.clientX
  y = ev.y or ev.clientY
  fillGaps(x - startDragX, y - startDragY)
  isDragging = false
  startDragX = startDragY = null
  canvas.removeEventListener("mousemove", dragImage)

canvas.addEventListener("mousedown", startDrag)
window.addEventListener("mouseup", stopDrag)


dragImage = (ev) ->
  # cancelJobs()
  x = ev.x or ev.clientX
  y = ev.y or ev.clientY
  dx = x - startDragX
  dy = y - startDragY

  # bck = ctx.getImageData(0, 0, canvas.width, canvas.height)
  ctx.fillStyle = "#000"
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.putImageData(snapshot, dx, dy)

  if dx*dx + dy*dy > 100
    console.log "travelled more than 100 px from the start"


# redraw the fractal after a drag&drop
# the argument are the coordinate (pixels) of the new center of the image
fillGaps = (dpx, dpy) ->
  dx = dpx * (xmax0 - xmin0)/canvas.width
  xmin0 -= dx
  xmax0 -= dx

  dy = dpy * (ymax0 - ymin0)/canvas.height
  ymin0 -= dy
  ymax0 -= dy

  console.log "dpx, dpy: #{dpx}, #{dpy}"
  if Math.abs(dpx) > 5
    if dx<0
      sliceRenderer(canvas.width+dpx, 0, -dpx, canvas.height, xmax0+dx, xmax0, ymin0, ymax0)
    else
      sliceRenderer(0, 0, dpx, canvas.height, xmin0, xmin0+dx, ymin0, ymax0)

  if Math.abs(dpy) > 5
    if dpy<0
      sliceRenderer(0, canvas.height+dpy, canvas.width, -dpy, xmin0, xmax0, ymax0+dy, ymax0)
    else if dpy isnt 0
      sliceRenderer(0, 0, canvas.width, dpy, xmin0, xmax0, ymin0, ymin0+dy)



################################################################################ 
# zooming part
################################################################################ 

# firefox
canvas.addEventListener("DOMMouseScroll", _.debounce( (ev) ->
  cancelJobs()
  if ev.detail < 0
    zoomIn(ev.clientX, ev.clientY)
  else
    zoomOut(ev.clientX, ev.clientY)
, 50))


# webkit (and ie ?)
canvas.addEventListener("mousewheel", _.debounce( (ev) ->
  cancelJobs()
  if ev.wheelDeltaY > 0
    zoomIn(ev.x, ev.y)
  else
    zoomOut(ev.x, ev.y)
, 50))

# @args cpx, cpy: position (pixel) of the cursor.
zoomIn = (cpx, cpy) ->
  zoomFactor++

  pixels = ctx.getImageData(0, 0, canvas.width, canvas.height)
  pixelsData = pixels.data

  cx = xmin0 + cpx * (xmax0-xmin0)/canvas.width
  cy = ymin0 + cpy * (ymax0-ymin0)/canvas.height
  newXwidth = (xmax0 - xmin0) / 2
  newYheight = (ymin0 - ymax0) / 2

  xRatio = cpx/canvas.width
  yRatio = cpy/canvas.height

  xmin0 = cx - newXwidth*xRatio
  xmax0 = cx + newXwidth*(1-xRatio)
  ymin0 = cy + newYheight*yRatio
  ymax0 = cy - newYheight*(1-yRatio)
  sliceRenderer(0, 0, canvas.width, canvas.height, xmin0, xmax0, ymin0, ymax0)


  # from here, compute a preview of the zoom image by stretching the zoomed part to fill
  # the current canvas
  # the part of the image to be zoomed is a rectangle (px0Zoomed, py0Zoomed, wZoomed, hZoomed)
  wZoomed = Math.floor(canvas.width/2)
  hZoomed = Math.floor(canvas.height/2)
  px0Zoomed = Math.floor(cpx - wZoomed*cpx/canvas.width)
  py0Zoomed = Math.floor(cpy - hZoomed*cpy/canvas.height)
  zoomed = ctx.getImageData(px0Zoomed, py0Zoomed, wZoomed, hZoomed)
  zoomedData = [].slice.call(zoomed.data)
  j = 0
  while j < hZoomed
    i = 0
    while i < wZoomed
      posZoomed = (j*wZoomed+i)*4
      r = zoomedData[posZoomed]
      g = zoomedData[posZoomed+1]
      b = zoomedData[posZoomed+2]
      a = zoomedData[posZoomed+3]

      pos1 = (j*canvas.width+i)*4*2
      pos2 = pos1 + 4
      pos3 = pos1 + canvas.width*4
      pos4 = pos3 + 4

      pixelsData[pos1+0] = r
      pixelsData[pos1+1] = g
      pixelsData[pos1+2] = b
      pixelsData[pos1+4] = a

      pixelsData[pos2+0] = r
      pixelsData[pos2+1] = g
      pixelsData[pos2+2] = b
      pixelsData[pos2+4] = a

      pixelsData[pos3+0] = r
      pixelsData[pos3+1] = g
      pixelsData[pos3+2] = b
      pixelsData[pos3+4] = a

      pixelsData[pos4+0] = r
      pixelsData[pos4+1] = g
      pixelsData[pos4+2] = b
      pixelsData[pos4+4] = a

      i++
    j++

  pixels.data = pixelsData
  ctx.putImageData(pixels, 0, 0)
  return

zoomOut = (cpx, cpy) ->
  zoomFactor--
  cx = xmin0 + cpx * (xmax0 - xmin0)/canvas.width
  cy = ymin0 + cpy * (ymax0 - ymin0)/canvas.height
  newXwidth = (xmax0 - xmin0) * 2
  newYheight = (ymax0 - ymin0) * 2

  xRatio = cpx/canvas.width
  yRatio = cpy/canvas.height

  xmin0 = xmin0 - newXwidth/2*xRatio
  xmax0 = xmax0 + newXwidth/2*(1-xRatio)
  ymin0 = ymin0 - newYheight/2*yRatio
  ymax0 = ymax0 + newYheight/2*(1-yRatio)

  sliceRenderer(0, 0, canvas.width, canvas.height, xmin0, xmax0, ymin0, ymax0)

  # from here, compute a preview of the zoomed out image by shrinking the current image
  pixels = ctx.getImageData(0, 0, canvas.width, canvas.height)
  pixelsData = pixels.data

  px0Shrunk = Math.floor(cpx/2)
  py0Shrunk = Math.floor(cpy/2)
  wShrunk = Math.floor(canvas.width/2)
  hShrunk = Math.floor(canvas.height/2)
  shrunk = ctx.createImageData(wShrunk, hShrunk)

  j = 0
  while j < hShrunk
    i = 0
    while i < wShrunk
      pos = (j*wShrunk+i)*4
      pixelPos = (j*canvas.width+i)*4*2
      shrunk.data[pos+0] = pixelsData[pixelPos+0]
      shrunk.data[pos+1] = pixelsData[pixelPos+1]
      shrunk.data[pos+2] = pixelsData[pixelPos+2]
      shrunk.data[pos+3] = pixelsData[pixelPos+3]
      i++
    j++

  ctx.fillStyle = "#000"
  ctx.fillRect(0,0,canvas.width,canvas.height)
  ctx.putImageData(shrunk, px0Shrunk, py0Shrunk)
  return

window.recompute = (l) ->
  cancelJobs()
  sliceRenderer(0,0,canvas.width,canvas.height,xmin0,xmax0,ymin0,ymax0, l)
  return zoomFactor

sliceRenderer(0, 0, canvas.width, canvas.height, xmin0, xmax0, ymin0, ymax0)

# manage controls
document.querySelector("#zoomIn").addEventListener("click", (ev) ->
  console.log "clicked on zoomIn ", ev
  zoomIn(Math.floor(canvas.width/2), Math.floor(canvas.height/2))
)

document.querySelector("#zoomOut").addEventListener("click", (ev) ->
  zoomOut(Math.floor(canvas.width/2), Math.floor(canvas.height/2))
)
