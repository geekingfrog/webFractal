# some variables
# width = 600
# height = 400
# ratio = width/height
# xmin = -2
# xmax = 1
# ymin = -1
# ymax = ymin + (xmax-xmin)/ratio


# some variables

# fullscreen
canvas = document.querySelector("canvas")
canvas.width = window.innerWidth
canvas.height = window.innerHeight

# current logical coordinates
xmax = xmin = ymax = ymin = 0

xmax0 =  1
xmin0 = -3
ymin0 = -1
ymax0 = ymin0 + (xmax0-xmin0)/(canvas.width/canvas.height)
z = 0

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
sliceRenderer = (px, py, width, height) ->
  tileW = 200
  tileH = 200
  nbrXTiles = Math.ceil(width/tileW)
  nbrYTiles = Math.ceil(height/tileH)

  stepX = (xmax-xmin)*tileW/width
  stepY = (ymax-ymin)*tileH/height

  i = 0
  while i <= Math.ceil(width/tileW)
    j = 0
    while j <= Math.ceil(height/tileH)
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

  processJobs()


zoom = (newZ) ->
  xmax = xmax0<<newZ
  xmin = xmin0<<newZ
  ymax = ymax0<<newZ
  ymin = ymin0<<newZ

zoom(z)

sliceRenderer(0, 0, canvas.width, canvas.height)

