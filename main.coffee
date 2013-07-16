# some variables

# fullscreen
canvas = document.querySelector("canvas")
canvas.width = window.innerWidth
canvas.height = window.innerHeight


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
nbrWorker = 8
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
  tileW = 400
  tileH = 400
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
canvas.addEventListener("mousedown", (ev) ->
  isDragging = true
  startDragX = ev.x or ev.clientX
  startDragY = ev.y or ev.clientY
  snapshot = ctx.getImageData(0, 0, canvas.width, canvas.height)
  canvas.addEventListener("mousemove", dragImage)
)

window.addEventListener("mouseup", (ev) ->
  x = ev.x or ev.clientX
  y = ev.y or ev.clientY
  fillGaps(x - startDragX, y - startDragY)
  isDragging = false
  startDragX = startDragY = null
  canvas.removeEventListener("mousemove", dragImage)
)

dragImage = (ev) ->
  cancelJobs()
  x = ev.x or ev.clientX
  y = ev.y or ev.clientY
  dx = x - startDragX
  dy = y - startDragY

  # bck = ctx.getImageData(0, 0, canvas.width, canvas.height)
  ctx.fillStyle = "#000"
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.putImageData(snapshot, dx, dy)

# redraw the fractal after a drag&drop
fillGaps = (dpx, dpy) ->
  console.log "fillgaps ?"
  dx = dpx * (xmax0 - xmin0)/canvas.width
  xmin0 -= dx
  xmax0 -= dx

  dy = dpy * (ymax0 - ymin0)/canvas.height
  ymin0 -= dy
  ymax0 -= dy

  if dx
    if dx<0
      sliceRenderer(canvas.width+dpx, 0, -dpx, canvas.height, xmax0+dx, xmax0, ymin0, ymax0)
    else
      sliceRenderer(0, 0, dpx, canvas.height, xmin0, xmin0+dx, ymin0, ymax0)

  if dy
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

zoomIn = (cpx, cpy) ->
  zoomFactor++
  console.log "zoomFactor: #{zoomFactor}"



  return
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

  return

zoomOut = (cpx, cpy) ->
  zoomFactor--
  return
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

window.recompute = (l) ->
  sliceRenderer(0,0,canvas.width,canvas.height,xmin0,xmax0,ymin0,ymax0, l)
  return zoomFactor

sliceRenderer(0, 0, canvas.width, canvas.height, xmin0, xmax0, ymin0, ymax0)
console.log "palette[0]: ", palette[0]

window.drawHsl = ->
  for i in [0...360]
    rgb = palettes.hslToRgb(i, 1, .5)
    ctx.fillStyle = palettes.rgb255ToCss(rgb)
    ctx.fillRect(700+i*2, 0, 2, canvas.height)


drawTonemap = ->
  palette = window.palettes.generatePalette(50)
  console.log "palette.length: ", palette.length
  palette.forEach( (color, i) ->
    ctx.fillStyle = palettes.rgb255ToCss(color)
    ctx.fillRect(30 + i*10, 0, 10, canvas.height)
  )

  return

drawTonemap()
drawHsl()
