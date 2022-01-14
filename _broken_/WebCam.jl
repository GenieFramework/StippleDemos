# Requires a webcam to be connected to the computer running this
# uses VideoUI only for determination of camera names and format
# images are converted to png by ffmpg
# Camera can be chosen by setting DEVICE_NO, e.g. `DEVICE_NO[] = 2`

using Stipple, StippleUI
using HTTP
using FFMPEG_jll, FileIO, VideoIO
import FFMPEG_jll.ffmpeg

import Base.cconvert
Base.cconvert(::Type{Ptr{Ptr{VideoIO.AVDictionary}}}, d::VideoIO.AVDict) = d.ref_ptr_dict

const SX = 640
const SY = 360
const FPS = 30 # some cameras only support fix values, e.g. 30
const FPS_CLIENT = 25
const FMT = Ref(unsafe_load(VideoIO.DEFAULT_CAMERA_FORMAT[]).name |> unsafe_string)
const DEVICE_NO = Ref(1)
const CAM_PROCESS = Ref(run(Sys.iswindows() ? `cmd /C` : `echo`)) # a container for the ffmpeg process
const IMG = Ref{Vector{UInt8}}() # a container for the last frame
const PORT = 8000

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

ffmpeg(f, cmd::Cmd; kwargs...) = ffmpeg(f ∘ (x->`$x $cmd`); kwargs...)
ffmpeg(cmd::Cmd; kwargs...) = ffmpeg(String ∘ read, cmd; kwargs...)

_start_camera() = ffmpeg() do exe
    device = string("video=", get(VideoIO.CAMERA_DEVICES, DEVICE_NO[], "0"))
    @info "starting camera with '$device'"
    cam_process = open(`$exe -hide_banner -loglevel error -f $(FMT[]) -r $FPS -s $(SX)x$(SY) -i $device -c:v png -f image2pipe -`)
    @async while process_running(cam_process) # update the last frame from the pipe
        IMG[] = readpngdata(cam_process)
    end
    return cam_process
end

function stop_camera()
    while !process_exited(CAM_PROCESS[])
        kill(CAM_PROCESS[])
        sleep(0.1)
    end
end

function start_camera() # restart camera
    stop_camera()
    CAM_PROCESS[] = _start_camera()
end

@reactive! mutable struct WebCam <: ReactiveModel
    cameraon::R{Bool} = true
    imageurl::String = ""
    cameratimer::Int = 0
end

Stipple.js_methods(model::WebCam) = """
    updateimage: function () { 
        this.imageurl = "frame/" + new Date().getTime();
    },
    startcamera: function () { 
        this.cameratimer = setInterval(this.updateimage, 1000/$(FPS_CLIENT));
    },
    stopcamera: function () { 
        clearInterval(this.cameratimer);
    }
"""

Stipple.js_created(model::WebCam) = """
    if (this.cameraon) { this.startcamera() }
"""

Stipple.js_watch(model::WebCam) = """
    cameraon: function (newval, oldval) { 
        this.stopcamera()
        if (newval) { this.startcamera() }
    }
"""

function ui(model)
    start_camera()

    on(model.cameraon) do ison
        ison ? start_camera() : stop_camera()
    end

    dashboard(model, [      
            p(quasar(:img, "", src=:imageurl, :basic, style="
                -webkit-app-region: drag;
                border-radius: 50%;
                width: 95vw;
                height: 95vw"),
            style = "margin: 1px"),

            p(toggle("", fieldname = :cameraon)),
    ], title = "WebCam") * 
    script("""document.documentElement.style.setProperty("--st-dashboard-bg", "#0000")""") *
    style("::-webkit-scrollbar { width: 0px; }")
end


route("/") do
    init(WebCam) |> ui |> html
end

route("frame/:timestamp") do
    global IMG
    HTTP.Messages.Response(200, IMG[])
end

Genie.config.server_host = "127.0.0.1"

up(PORT)

using Electron

function camerawidget()
    win = Window(URI("http://localhost:$PORT"), options = Dict(
        "transparent" => true,
        "frame" => false,
        "width" => 145,
        "height" => 200,
    ))
    
    ElectronAPI.setAlwaysOnTop(win, true)
    win
end

win = camerawidget()