# some variables
width = 600
height = 400
ratio = width/height
xmin = -2
xmax = 1
ymin = -1
ymax = ymin + (xmax-xmin)/ratio
# compute only the first term of the serie to check if it'll diverge

canvas = document.getElementById("fractal")
canvas.width = width
canvas.height = height
window.ctx = canvas.getContext("2d")

ctx.fillStyle = "#ef0000"


#fx^-1(x) and fy^-1(y) convert pixel to logical coordinates
window.toX = (px) ->
  px*(xmax-xmin)/width + xmin

window.toY = (py) ->
  (py*(ymax-ymin)/height + ymin)

colorScale = ("rgb(#{step},#{step},#{step})" for step in [0...250] by 12)

# compute the #{limit} first term of the mandlebrot serie.
# return false if the given point will not diverge
# otherwise, return the iteration at which the module was greater than 2
# To speed up things, all computation is done with squared value (no square root)
# z0 = 0
# z_n+1 = z_n^2 + c
isDiverging = (cx, cy, limit) ->
  n = 1
  zx = cx
  zy = cy
  while n<limit
    # if zx*zx + zy*zy > (width/4)*width
    if zx*zx + zy*zy > 4
      return n
    tmp = zx*zx - zy*zy
    zy = 2*zx*zy + cy
    zx = tmp + cx
    n++
  return false


pixelSize = 1
start = Date.now()
console.log "starting at #{start}"
window.draw = (limit) ->
  for px in [0..width] by pixelSize
    dx = Math.abs(width/2 - px)
    x = toX(px)
    for py in [0..height] by pixelSize
      dy = Math.abs(height/2 - py)
      d = (dx*dx + dy*dy)
      diverge = isDiverging(x, toY(py), limit)
      if diverge
        colorIdx = Math.floor(diverge * (colorScale.length-1)/limit)
        ctx.fillStyle = colorScale[colorIdx]
      else
        ctx.fillStyle = "#111"
      ctx.fillRect(px, py, pixelSize, pixelSize)

# draw(20)

limit = 100
nextDrawing = null
progressiveDraw = (n = 10) ->
  if n < limit
    draw(n)
    nextDrawing = setTimeout( ->
      progressiveDraw(n+10)
    , 500)
  else
    nextDrawing = null

# progressiveDraw()


# return the absolute position of the element relative to the window
# probably break if scrolling
findPos = (el) ->
  offsetTop = 0
  offsetLeft = 0
  node = el
  while node.offsetParent
    offsetTop += node.offsetTop
    offsetLeft += node.offsetLeft
    node = node.offsetParent
  return {top: offsetTop, left: offsetLeft}

selection = document.querySelector(".selection")
offset = findPos(document.querySelector("#container"))
console.log "offset: ", offset
startX = 0
startY = 0

canvas.addEventListener("mousewheel", (ev) ->
  ev.preventDefault()
  cx = toX(ev.x-offset.left)
  cy = toY(ev.y-offset.top)
  if ev.wheelDeltaY > 0
    zoomIn(cx, cy)
  else
    zoomOut(cx, cy)
)

zoomIn = (cx ,cy) ->
  newW = (xmax-xmin) / 2
  xmin = cx - newW/2
  xmax = cx + newW/2

  newH = newW/ratio
  ymin = cy - newH/2
  ymax = cy + newH/2
  console.log "center of zoom: (#{cx}, #{cy})"
  console.log "new ranges: [#{xmin}, #{xmax}] [#{ymin}, #{ymax}]"
  if nextDrawing
    clearTimeout(nextDrawing)
  progressiveDraw()


zoomOut = (cx, cy) ->
  newW = (xmax-xmin) * 2
  if newW >= 3 # recenter to the initial state
    cx = -.5
    cy = 0
    newW = 3
  xmin = cx - newW/2
  xmax = cx + newW/2

  newH = newW/ratio
  ymin = cy - newH/2
  ymax = cy + newH/2
  if nextDrawing
    clearTimeout(nextDrawing)
  progressiveDraw()


console.log "done after #{Date.now() - start} ms (at #{Date.now()})"

mandlebrot = (cx, cy, limit) ->
  n = 1
  zx = cx
  zy = cy
  while n<limit
    if zx*zx + zy*zy > 4
      return n
    tmp = zx*zx - zy*zy
    zy = 2*zx*zy + cy
    zx = tmp + cx
    n++
  return false

# ten green from darker to lighter
greenPalette = do (n=10) ->
  poly = (x) -> Math.floor(x*x*x - 85*x*x + 340*x)
  palette = for i in [0...n]
    [0, poly(i/n), 0]
  return palette

for color, i in greenPalette
  n = greenPalette.length
  ctx.fillStyle = "rgb(#{color[0]}, #{color[1]}, #{color[2]})"
  ctx.fillRect(i*width/n, 0, width/n, height)

# take an object as argument which contains the instruction to draw a fractal
# and returns a UintClampedArray to draw on a canvas
# data:
#   xmin: logical xmin and xmax
#   xmax
#   ymin: logical ymin and ymax
#   ymax
#   pxWidth: number of pixel (width)
#   pxHeight: number of pixel (height)
#   palette: the color palette to use, palette[i] is an array of 3 int for rgb()
computeFractal = (data) ->
  {xmax, xmin, ymax, ymin, pxWidth, pxHeight, palette, limit} = data
  # res = new Uint8ClampedArray(pxWidth*pxHeight*4)
  res = ctx.createImageData(pxWidth, pxHeight)

  # transform a pixel coordinate into a logical coordinate
  # (0, 0) -> (xmin, ymin)
  toX = (px) ->
    px*(xmax-xmin)/pxWidth + xmin

  toY = (py) ->
    (py*(ymax-ymin)/pxHeight + ymin)

  for py in [0...pxHeight]
    cy = toY(py)
    for px in [0...pxWidth]
      cx = toX(px)
      res.data[0+((py*pxWidth + px)<<2)] = Math.floor(Math.random()*255)
      res.data[1+((py*pxWidth + px)<<2)] = Math.floor(Math.random()*255)
      res.data[2+((py*pxWidth + px)<<2)] = Math.floor(Math.random()*255)
      res.data[3+((py*pxWidth + px)<<2)] = 255

      divIdx = mandlebrot(cx, cy, limit)
      if divIdx
        color = palette[Math.floor(divIdx*(palette.length-1)/limit)]
        res.data[0+((py*pxWidth + px)<<2)] = color[0]
        res.data[1+((py*pxWidth + px)<<2)] = color[1]
        res.data[2+((py*pxWidth + px)<<2)] = color[2]
        res.data[3+((py*pxWidth + px)<<2)] = 255
      else
        res.data[0+((py*pxWidth + px)<<2)] = 0
        res.data[1+((py*pxWidth + px)<<2)] = 0
        res.data[2+((py*pxWidth + px)<<2)] = 0
        res.data[3+((py*pxWidth + px)<<2)] = 255

  return res

window.test = ->
  # test to build the fractal in multiple times

  width0 = 600
  height0 = 400
  xmax0 =  1
  xmin0 = -2
  ymin0 = -1
  ymax0 = ymin0 + (xmax0-xmin0)/(width0/height0)
  xSlices = 5

  xSlices = 20
  ySlices = 10
  for i in [0...xSlices]
    for j in [0...ySlices]
      data = {
        pxWidth: width0/xSlices
        pxHeight: height0/ySlices
        xmin: xmin0 + i/xSlices*(xmax0-xmin0)
        xmax: xmin0 + (i+1)/xSlices*(xmax0-xmin0)
        ymin: ymin0 + j/ySlices*(ymax0-ymin0)
        ymax: ymin0 + (j+1)/ySlices*(ymax0-ymin0)
        palette: greenPalette
        limit: 500
      }
      ctx.putImageData(computeFractal(data), i/xSlices*width0, j/ySlices*height0)

start = Date.now()
test()
console.log "done in #{Date.now()-start} ms"

