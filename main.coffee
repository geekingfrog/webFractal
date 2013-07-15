# some variables

# fullscreen
canvas = document.querySelector("canvas")
canvas.width = window.innerWidth
canvas.height = window.innerHeight


xmax0 =  1
xmin0 = -3
ymin0 = -1
ymax0 = ymin0 + (xmax0-xmin0)/(canvas.width/canvas.height)
zoomFactor = 1

canvas = document.getElementById("fractal")
ctx = canvas.getContext("2d")
ctx.fillStyle = "#000"
ctx.fillRect(0,0,canvas.width, canvas.height)

# create workers
nbrWorker = 10
idleWorkers = []
jobQueue = []
workingWorkers = {}
for i in [0...nbrWorker]
  worker = new Worker("fractalWorker.js")
  idleWorkers.push worker
  worker.addEventListener("message", (e) ->
    ctx.putImageData(e.data.img, e.data.px0, e.data.py0)
    idleWorkers.push this # put the worker back in the queue
    delete workingWorkers[e.data.workerId]
    processJobs()
  )


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
  }
  jobQueue.push jobData


processJobs = ->
  while jobQueue.length and idleWorkers.length
    worker = idleWorkers.pop()
    job = jobQueue.shift()
    workerId = Date.now()
    job.workerId = workerId
    workingWorkers[workerId] = workerId
    worker.postMessage(job)

cancelJobs = ->
  for workerId, worker of workingWorkers
    worker.postMessage({cmd: "cancel"})

# limit if a function of the zoomfactor
computeLimit = (zoom) ->
  if zoom > 0
    return 100 + zoom*50
  else
    return 150

# take a rectangle as an input and create
# tiles from it to be rendered by different workers
# no clipping handling for the moment, assume parameters are correct and
# in range
window.sliceRenderer = (px, py, width, height, xmin, xmax, ymin, ymax, limit = computeLimit(zoomFactor)) ->
  console.log "calling sliceRenderer with args: ", arguments
  tileW = width
  tileH = height
  tileW = 100
  tileH = 100
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
      # console.log "job data: ", jobData

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
  startDragX = ev.x
  startDragY = ev.y
  snapshot = ctx.getImageData(0, 0, canvas.width, canvas.height)
  canvas.addEventListener("mousemove", dragImage)
)

window.addEventListener("mouseup", (ev) ->
  fillGaps(ev.x - startDragX, ev.y - startDragY)
  isDragging = false
  startDragX = startDragY = null
  canvas.removeEventListener("mousemove", dragImage)
)

dragImage = (ev) ->
  {x,y} = ev
  dx = x - startDragX
  dy = y - startDragY

  # bck = ctx.getImageData(0, 0, canvas.width, canvas.height)
  ctx.fillStyle = "#000"
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.putImageData(snapshot, dx, dy)

# redraw the fractal after a drag&drop
fillGaps = (dpx, dpy) ->
  console.log "filling gap for dx, dy: #{dpx}, #{dpy}"

  dx = dpx * (xmax0 - xmin0)/canvas.width
  xmin0 -= dx
  xmax0 -= dx

  dy = dpy * (ymax0 - ymin0)/canvas.height
  ymin0 -= dy
  ymax0 -= dy
  console.log "(dx, dy) = (#{dx}, #{dy})"

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
canvas.addEventListener("mousewheel", (ev) ->
  console.log ev
  if ev.wheelDeltaY > 0
    zoomIn(ev.x, ev.y)
  else
    zoomOut(ev.x, ev.y)
)

zoomIn = (cpx, cpy) ->
  zoomFactor++
  console.log "zooming with center: #{cpx}, #{cpy}"
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
  # below an attempt to create a temporary zoomed image from the already rendered
  # canvas
  zoomed = ctx.createImageData(canvas.width, canvas.height)
  zoomedWidth = Math.ceil(canvas.width/2)
  zoomedHeight = Math.ceil(canvas.height/2)
  sliceToZoom = ctx.getImageData(
    Math.floor(cpx-canvas.width/2), Math.floor(cpy-canvas.height/2),
    zoomedWidth, zoomedHeight
  )
  console.log "sliceToZoom: ", sliceToZoom
  console.log "zoomed: ", zoomed
  console.log "ratio: ", sliceToZoom.data.length/zoomed.data.length

  bck = ctx.getImageData(0,0, canvas.width, canvas.height)
  ox = cpx - Math.floor(canvas.width/2)
  oy = cpy - Math.floor(canvas.height/2)

  j = 0
  while j < canvas.height
    i = 0
    while i < canvas.width
      startPx1 = (i*canvas.width + j)*4
      target = 4*(canvas.width*(ox + Math.floor(i/2)) + oy + Math.floor(j/2))
      zoomed.data[startPx1+0] = bck.data[target+0]
      zoomed.data[startPx1+1] = bck.data[target+1]
      zoomed.data[startPx1+2] = bck.data[target+2]
      zoomed.data[startPx1+3] = bck.data[target+3]

      startPx2 = startPx1 + 1
      zoomed.data[startPx2+0] = bck.data[target+0]
      zoomed.data[startPx2+1] = bck.data[target+1]
      zoomed.data[startPx2+2] = bck.data[target+2]
      zoomed.data[startPx2+3] = bck.data[target+3]

      startPx3 = startPx1 + canvas.width
      zoomed.data[startPx3+0] = bck.data[target+0]
      zoomed.data[startPx3+1] = bck.data[target+1]
      zoomed.data[startPx3+2] = bck.data[target+2]
      zoomed.data[startPx3+3] = bck.data[target+3]

      startPx4 = startPx3 + 1
      zoomed.data[startPx4+0] = bck.data[target+0]
      zoomed.data[startPx4+1] = bck.data[target+1]
      zoomed.data[startPx4+2] = bck.data[target+2]
      zoomed.data[startPx4+3] = bck.data[target+3]

      i++
    j++
  ctx.putImageData(zoomed, 0, 0)

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

window.recompute = (l) ->
  sliceRenderer(0,0,canvas.width,canvas.height,xmin0,xmax0,ymin0,ymax0, l)
  return zoomFactor

sliceRenderer(0, 0, canvas.width, canvas.height, xmin0, xmax0, ymin0, ymax0)
