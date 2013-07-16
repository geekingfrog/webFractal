importScripts("lib/q/q.js")
self.cancelTask = false

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
  return n

# ten green from darker to lighter
greenPalette = do (n=10) ->
  poly = (x) -> Math.floor(x*x*x - 85*x*x + 340*x)
  palette = for i in [0...n]
    [0, poly(i/n), 0]
  return palette


# take an object as argument which contains the instruction to draw a fractal
# returns a promise which is resolved when the original array has been modified with
# the newly computed values
# data:
#   xmin: logical xmin and xmax
#   xmax
#   ymin: logical ymin and ymax
#   ymax
#   pxWidth: number of pixel (width)
#   pxHeight: number of pixel (height)
#   palette: the color palette to use, palette[i] is an array of 3 int for rgb()
computeFractal = (data) ->
  {xmax, xmin, ymax, ymin, pxWidth, pxHeight, palette, limit, imgData} = data
  palette = palette or greenPalette

  # transform a pixel coordinate into a logical coordinate
  # (0, 0) -> (xmin, ymin)
  toX = (px) ->
    px*(xmax-xmin)/pxWidth + xmin

  toY = (py) ->
    (py*(ymax-ymin)/pxHeight + ymin)

  computeRow = (py, cy) ->
    for px in [0...pxWidth]
      cx = toX(px)
      divIdx = mandlebrot(cx, cy, limit)
      if divIdx
        color = palette[Math.floor(divIdx*(palette.length-1)/limit)]
        imgData.data[0+((py*pxWidth + px)<<2)] = color[0]
        imgData.data[1+((py*pxWidth + px)<<2)] = color[1]
        imgData.data[2+((py*pxWidth + px)<<2)] = color[2]
        imgData.data[3+((py*pxWidth + px)<<2)] = 255
      else
        imgData.data[0+((py*pxWidth + px)<<2)] = 0
        imgData.data[1+((py*pxWidth + px)<<2)] = 0
        imgData.data[2+((py*pxWidth + px)<<2)] = 0
        imgData.data[3+((py*pxWidth + px)<<2)] = 255
    return true


  computePromise = Q()
  for py in [0...pxHeight]
    do (py) ->
      cy = toY(py)
      computePromise = computePromise.then(->
        if self.cancelTask
          throw "cancelled"
        else
          return computeRow(py, cy)
      )
  return computePromise


self.addEventListener('message', (e) ->
  if e.data.cmd is "cancel"
    self.cancelTask = true
  else
    imgPromise = computeFractal(e.data)
    imgPromise.done( ->
      self.postMessage({
        img: e.data.imgData
        px0: e.data.px0
        py0: e.data.py0
        queueDate: e.data.queueDate
      })
    , (reason) -> #on rejection
      # noop
    )
)
