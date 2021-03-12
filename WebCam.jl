# Requires a webcam to be connected to the computer running this

using Stipple, StippleUI
using HTTP
using FFMPEG_jll, FileIO


const SX = 640
const SY = 360
const FPS = 30 # some cameras only support fix values, e.g. 30
const FPS_CLIENT = 5
const FMT = Sys.iswindows() ? "dshow" : "v4l2"
const DEVICE = Sys.iswindows() ? "video=\"Integrated Webcam\"" : "/dev/video0"
const CAM_PROCESS = Ref(run(Sys.iswindows() ? `cmd /C` : `echo`)) # a container for the process running ffmpeg
const IMGPATH = "img/demo.png"

# capture output, std_out, std_err and error information in case of failure
macro capture(expr)
    quote
        original_stdout = stdout
        original_stderr = stderr
        (so_rd, so_wr) = redirect_stdout();
        (se_rd, se_wr) = redirect_stderr();

        out = try
            eval($(esc(expr)))
        catch ex
            ex
        end
        
        redirect_stdout(original_stdout)
        redirect_stderr(original_stderr)
        close(so_wr)
        close(se_wr)

        so = String(read(so_rd))
        se = String(read(se_rd))

        (out, so, se)
    end
end

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

import FFMPEG_jll.ffmpeg
ffmpeg(f, cmd::Cmd; kwargs...) = ffmpeg(f ∘ (x->`$x $cmd`); kwargs...)
ffmpeg(cmd::Cmd; kwargs...) = ffmpeg(String ∘ read, cmd; kwargs...)

function _get_camera()
    # strangely ffmpeg outputs to std_err and exits with exit code 1
    # so we have to do some acrobatics to capture its output
    (_, _, out) = @capture ffmpeg(`-list_devices true -f dshow -i dummy`)
    
    # exctract the name of the first video device
    m = match(r"""DirectShow video devices.+?"([^"]+)"""s, out)
    isnothing(m) ? "" : m.captures[1]
end

_start_camera() = ffmpeg() do exe
    device = if Sys.iswindows()
        cam = _get_camera()
        cam == "" ? `no_device_found` : `video=$cam`
    else
        DEVICE
    end
    io = open(`$exe -hide_banner -loglevel error -f $FMT -r $FPS -s $(SX)x$SY -i $device -c:v png -f image2pipe -`)
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
    imageurl::R{String} = IMGPATH
end

function restart()
    global model
    model = Stipple.init(WebCam(), debounce=1)

    start_camera()

    on(model.cameraon) do ison
        ison ? start_camera() : killcam()
    end
end


Stipple.js_methods(model::WebCam) = """"""

Stipple.js_watch(model::WebCam) = """
    cameraon: function (newval, oldval) { 
        if (this.camera == undefined) { this.camera = 0 };
        if (this.camera) { clearInterval(this.camera) };
        if (newval) {
            this.camera = setInterval(function() {
                WebCam.imageurl = "frame/" + new Date().getTime();
            }, 1000/$FPS_CLIENT);
        }
    }
"""

function ui()
    m = dashboard(vm(model), [      
        heading("WebCam"),
        row(cell(class="st-module", [ # using <img/> instead of quasar's becuase of the `img id = "frame"` that is used by the JS above to update the `src` from the client side
            quasar(:img, "", src=:imageurl, :basic, style="height: 140px; max-width: 150px")
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