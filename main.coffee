# some variables

# fullscreen
canvas = document.querySelector("canvas")
canvas.width = window.innerWidth
canvas.height = window.innerHeight


xmax0 =  1
xmin0 = -3
ymin0 = -1
ymax0 = ymin0 + (xmax0-xmin0)/(canvas.width/canvas.height)

canvas = document.getElementById("fractal")
ctx = canvas.getContext("2d")

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


# take a rectangle as an input and create
# tiles from it to be rendered by different workers
# no clipping handling for the moment, assume parameters are correct and
# in range
sliceRenderer = (px, py, width, height, xmin, xmax, ymin, ymax) ->
  console.log "calling sliceRenderer with args: ", arguments
  tileW = 200
  tileH = 200
  nbrXTiles = Math.ceil(width/tileW)
  nbrYTiles = Math.ceil(height/tileH)

  stepX = (xmax-xmin)*tileW/width
  stepY = (ymax-ymin)*tileH/height

  i = 0
  while i <= Math.ceil(width/tileW)
    j = 0
    w = if (i+1)*tileW > width then width-i*tileW else tileW
    while j <= Math.ceil(height/tileH)
      h = if (j+1)*tileH > height then height-j*tileH else tileH
      addJob({
        width: tileW
        height: tileH
        xmin: xmin + i*stepX
        xmax: xmin + (i+1)*stepX
        ymin: ymin + j*stepY
        ymax: ymin + (j+1)*stepY
        limit: 500
        px0: i*tileW
        py0: j*tileH
      })
      j++
    i++

  for j in jobQueue
    console.log j
  processJobs()

isDragging = false
startDragX = startDragY = null
snapshot = null
canvas.addEventListener("mousedown", (ev) ->
  isDragging = true
  console.log "ev: ", ev
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

dragImage = _.throttle( (ev) ->
    {x,y} = ev
    dx = x - startDragX
    dy = y - startDragY
    console.log "(dx, dy) = (#{dx}, #{dy})"

    # bck = ctx.getImageData(0, 0, canvas.width, canvas.height)
    ctx.fillStyle = "#000"
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    ctx.putImageData(snapshot, dx, dy)
  , 50)

 
# redraw the fractal after a drag&drop
fillGaps = (dx, dy) ->
  console.log "filling gap for dx, dy: #{dx}, #{dy}"
  if dx>0
    startX = 0
    w = dx
    xmin = xmin0
    xmax = xmin0 + dx*(xmax0-xmin0)/canvas.width
  else
    startX = canvas.width + dx
    w = -dx
    xmin = xmax0 + dx*(xmax0-xmin0)/canvas.width
    xmax = xmax0

  if dy>0
    startY = 0
    h = dy
    ymin = ymin0
    ymax = ymin0 + dy*(ymax0-ymin0)/canvas.height
  else
    startY = canvas.height + dy
    h = -dy
    ymin = ymax0 + dy*(ymax0-ymin0)/canvas.height
    ymax = ymax0

  # three parts
  # sliceRenderer(startX, startY, canvas.width, h, xmin, xmax, ymin, ymax)
  sliceRenderer(0, startY, canvas.width, h, xmin0, xmax0, ymin, ymax)



window.test = ->
  bck = ctx.getImageData(0,0,canvas.width, canvas.height)
  ctx.fillStyle = "#000"
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.putImageData(bck, -100,0)

sliceRenderer(0, 0, canvas.width, canvas.height, xmin0, xmax0, ymin0, ymax0)
# sliceRenderer(0, 0, canvas.width, 100, xmin0, xmax0, 0, 0.1)

