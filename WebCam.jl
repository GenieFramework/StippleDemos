# Reuires a webcam to be connected to the computer running this

using Stipple, StippleUI
using Genie.Renderer.Html
using HTTP
using FFMPEG_jll, FileIO

const SZ = 640 # width and height of the images
const FPS = 5 # frames per second
const CAM_PROCESS = Ref(run(`echo`)) # a container for the process running ffmpeg

function readpngdata(io) # taken from Per Rutquist (@Per) https://github.com/perrutquist/FFmpegPipe.jl/blob/cc2d73acfa8ce55e3e4e53b8264c94477fa0bce3/src/FFmpegPipe.jl#L74
    blk = 65536;
    a = Array{UInt8}(undef, blk)
    readbytes!(io, a, 8)
    if view(a, 1:8) != magic(format"PNG")
        error("Bad magic.")
    end
    n = 8
    while !eof(io)
        if length(a)<n+12
            resize!(a, length(a)+blk)
        end
        readbytes!(io, view(a, n+1:n+12), 12)
        m = 0
        for i=1:4
            m = m<<8 + a[n+i]
        end
        chunktype = view(a, n+5:n+8)
        n=n+12
        if chunktype == codeunits("IEND")
            break
        end
        if length(a)<n+m
            resize!(a, max(length(a)+blk, n+m+12))
        end
        readbytes!(io, view(a, n+1:n+m), m)
        n = n+m
    end
    resize!(a,n)
    return a
end

const IMG = Ref{Vector{UInt8}}() # a container for the last frame

_start_camera() = ffmpeg() do exe
    io = open(`$exe -hide_banner -loglevel error -f v4l2 -r $FPS -s $(SZ)x$SZ -i /dev/video0 -c:v png -vf "crop=in_h:in_h,scale=$(SZ)x$SZ" -f image2pipe -`)
    @async while process_running(io) # update the last frame from the pipe
        IMG[] = readpngdata(io)
    end
    return io
end

killcam() = while !process_exited(CAM_PROCESS[]) # make sure camera is dead
    kill(CAM_PROCESS[])
    sleep(0.1)
end

function start_camera() # restart camera
    killcam()
    CAM_PROCESS[] = _start_camera()
end

Base.@kwdef mutable struct WebCam <: ReactiveModel
    cameraon::R{Bool} = true
end

function restart()

    start_camera()

    global model

    model = Stipple.init(WebCam(), debounce=1)

    on(model.cameraon) do ison
        ison ? start_camera() : killcam()
    end

end

function ui()
    m = dashboard(vm(model), [
                              script( # this should probably move to js_methods()
                                     """
                                     setInterval(function() {
                                     var img = document.getElementById("frame");
                                     img.src = "frame/" + new Date().getTime();
                                     }, $(1000 ÷ FPS));
                                     """
                                    ),        
                              heading("WebCam"),
                              row(cell(class="st-module", [ # using <img/> instead of quasar's becuase of the `img id = "frame"` that is used by the JS above to update the `src` from the client side
                                                           """
                                                           <img id="frame" src="frame" style="height: $(SZ)px; max-width: $(SZ)px" />
                                                           """
                                                          ])),
                              row(cell(class="st-module", [
                                                           p(toggle("Camera on", fieldname = :cameraon)),
                                                          ]))
                             ], title = "WebCam")

    return html(m)
end


route("/", ui)

route("frame/:timestamp") do 
    HTTP.Messages.Response(200, IMG[])
end

Genie.config.server_host = "127.0.0.1"

restart()

up(open_browser = true)



