window.palettes = {}

###
#hsl to rgb conversion
#http://www.rapidtables.com/convert/color/hsl-to-rgb.htm
###

# 0 <= h < 360
# 0 <= s <= 1
# 0 <= l <= 1
window.palettes.hslToRgb = hslToRgb = (h, s, l) ->
  while h < 0
    h+=360
  while h >= 360
    h-=360

  # http://www.rapidtables.com/convert/color/hsl-to-rgb.htm
  c = (1 - Math.abs(2*l - 1))*s
  x = c * (1 - Math.abs((h/60)%2 - 1))
  m = l - c/2

  r = g = b = 0
  if h < 60
    r = c
    g = x
  else if h < 120
    r = x
    g = c
  else if h < 180
    g = c
    b = x
  else if h < 240
    g = x
    b = c
  else if h < 300
    r = x
    b = c
  else
    r = c
    b = x

  return {
    r: Math.floor(255 * (r+m))
    g: Math.floor(255 * (g+m))
    b: Math.floor(255 * (b+m))
  }

window.palettes.rgb255ToCss = (color) ->
  if Object::toString.call(color) is "[object Array]"
    r = color[0]
    g = color[1]
    b = color[2]
  else
    {r,g,b} = color
  r = r.toString(16)
  r = "0"+r if r.length < 2
  g = g.toString(16)
  g = "0"+g if g.length < 2
  b = b.toString(16)
  b = "0"+b if b.length < 2
  return "#"+r+g+b

window.palettes.generateWarmPalette = (n) ->
  l = (x) ->
    Math.sqrt(.5*.5*(x+.1))

  palette = for i in [1..n]
    tmp = hslToRgb(80-60*i/n, 1, l(i/n))
    # tmp = hslToRgb(180+60*i/n, 1, .5)
    [tmp.r, tmp.g, tmp.b]
  return palette

window.palettes.generatePalette = (n) ->
  l = (x) ->
    Math.sqrt(.7*.7*(x+.2))

  palette = for i in [1..n]
    hue = 120 - 30*i/n

    # tmp = hslToRgb(hue, 1, l(i/n))
    tmp = hslToRgb(hue, 1, i/n*.5)
    [tmp.r, tmp.g, tmp.b]

  # oppositeColor = hslToRgb(115+180, 1, .5)
  # palette[n-1] = [oppositeColor.r, oppositeColor.g, oppositeColor.b]
  # palette[0] = [0,0,0]
  # palette[0] = [0,0,0]
  # palette[2] = [0,0,0]
  return palette



