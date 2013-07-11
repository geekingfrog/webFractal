# some variables
width = 600
height = 400
ratio = width/height
xmin = -2
xmax = 1
ymin = -1
ymax = ymin + (xmax-xmin)/ratio
# compute only the first term of the serie to check if it'll diverge
limit = 40


canvas = document.getElementById("fractal")
canvas.width = width
canvas.height = height
canvas.style.border = "1px solid black"
ctx = canvas.getContext("2d")

ctx.fillStyle = "#ef0000"

# x scale
# take a number in [xmin; xmax] and returns the corresponding pixel in the canvas
window.fx = (x) ->
  canvas.width/2 + x*canvas.width/4

# y scale
window.fy = (y) ->
  canvas.height/2 + y*canvas.height/4

#fx^-1(x) and fy^-1(y) convert pixel to logical coordinates
window.toX = (px) ->
  px*(xmax-xmin)/width + xmin

window.toY = (py) ->
  py*(ymax-ymin)/height + ymin

colorScale = ("rgb(#{step},#{step},#{step})" for step in [0...250] by 12)

# compute the #{limit} first term of the mandlebrot serie.
# return false if the given point will not diverge
# otherwise, return the iteration at which the module was greater than 2
# To speed up things, all computation is done with squared value (no square root)
# z0 = 0
# z_n+1 = z_n^2 + c
isDiverging = (cx, cy) ->
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
for px in [0..width] by pixelSize
  dx = Math.abs(width/2 - px)
  x = toX(px)
  for py in [0..height] by pixelSize
    dy = Math.abs(height/2 - py)
    d = (dx*dx + dy*dy)
    diverge = isDiverging(x, toY(py))
    if diverge
      colorIdx = Math.floor(diverge * (colorScale.length-1)/limit)
      ctx.fillStyle = colorScale[colorIdx]
    else
      ctx.fillStyle = "#111"
    ctx.fillRect(px, py, pixelSize, pixelSize)

console.log "done after #{Date.now() - start} ms (at #{Date.now()})"
