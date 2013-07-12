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
  {xmax, xmin, ymax, ymin, pxWidth, pxHeight, palette, limit, imgData} = data
  palette = palette or greenPalette

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
      imgData.data[0+((py*pxWidth + px)<<2)] = Math.floor(Math.random()*255)
      imgData.data[1+((py*pxWidth + px)<<2)] = Math.floor(Math.random()*255)
      imgData.data[2+((py*pxWidth + px)<<2)] = Math.floor(Math.random()*255)
      imgData.data[3+((py*pxWidth + px)<<2)] = 255

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

  return imgData



self.addEventListener('message', (e) ->
  img = computeFractal(e.data)
  self.postMessage({img: img, px0: e.data.px0, py0: e.data.py0, workerId: e.data.workerId})
)
