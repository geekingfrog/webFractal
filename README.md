# Mandlebrot set with html.
Small project to keep me busy while a typhoon is passing over Taiwan. The idea is to create beautiful fractals using the canvas element. To keep things responsives, web workers are used.
To draw something, the sliceRenderer function is called with the area on which to draw (in pixel) and the actual coordinates of the rectangle corresponding to this area in pixel. The function then slices this area in smaller area and delegate the computation of the fractal to a webworker. This allow one to redraw any part of the canvas independently and efficiently.

# Things to work on.
* More beautiful color palette. These are hard to get right but have a huge impact.
* I'd like to add an option to add (with preview) the corresponding Julia set for a given point. This is interesting because there is a direct link between the two sets. A point leading to multiple ramification in the Mandlebrot set gives a more complex (and usually prettier) Julia.
* Concurrency is not handled yet. That is, if a computation takes place and the user drag&drop or zoom, there will be some artefact (and probably some error). Need a way to cancel tasks.
* Zoom preview. Uses the currently rendered fractal zhen zooming while the refreshed set is computed.
