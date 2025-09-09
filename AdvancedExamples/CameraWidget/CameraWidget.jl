module CameraWidget

# WebCam: Camera Widget
# - uses VideoIO for determination of camera names and format
# - camera can be deactivated to allow for access from other video software
# - images are converted to png by ffmpg.exe
# - supports two update modes: "webchannel" (default) and "url"
# - supports multiple cameras, hardware and models are separated
# - browser refresh rate (model.fps) is reflected after reactivating the camera
# - model.fps = 0 together with model.updatemode = "webchannel" will update as fast as possible
# - this is the new default, so please provide model.fps > 0 in "url" updatemode.

export camerawidget

using Stipple
using StippleUI
using HTTP
using FileIO
using VideoIO
using Electron

import VideoIO.FFMPEG.ffmpeg
import Genie.Requests: payload

using Base64: base64encode
base64png(png) = "data:image/png;base64,$(base64encode(png))"

Base.@kwdef mutable struct Camera
    camera::String = get(VideoIO.CAMERA_DEVICES, 1, "0")

    process::Base.Process = run(Sys.iswindows() ? `cmd /C` : `echo`)
    fmt::String = unsafe_load(VideoIO.DEFAULT_CAMERA_FORMAT[]).name |> unsafe_string
    img::Vector{UInt8} = UInt8[]

    sx::Int = 640
    sy::Int = 360
    fps::Int = 30 # auto in "webchannel" updatemode
end

const PORT = 8000
CAMERAS = Dict{UInt64, Camera}()

empty!(CAMERAS)
opencamera()

for camera in VideoIO.CAMERA_DEVICES
    push!(CAMERAS, hash(camera) => Camera(;camera))
end

# Stipple imports `view` via Html, therefore it needs to be explicitly imported
import Base.view

# `readpngdata` taken from Per Rutquist (@Per) https://github.com/perrutquist/FFmpegPipe.jl/blob/cc2d73acfa8ce55e3e4e53b8264c94477fa0bce3/src/FFmpegPipe.jl#L74
function readpngdata(io)
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

start_camera(camera::Camera) = ffmpeg() do exe
    stop_camera(camera)
    device = string("video=", camera.camera)
    @info "starting camera with '$device'"
    camera.process = open(`$exe -hide_banner -loglevel error -f $(camera.fmt) -r $(camera.fps) -s $(camera.sx)x$(camera.sy) -i $device -c:v png -f image2pipe -`)
    @async while process_running(camera.process)
        camera.img = readpngdata(camera.process)
    end
    return camera.process
end

function stop_camera(camera::Camera)
    while !process_exited(camera.process)
        kill(camera.process)
        sleep(0.1)
    end
end

@vars WebCam begin
    camera = CAMERAS[hash(first(VideoIO.CAMERA_DEVICES))].camera
    cameraon = false
    cameratimer = 0, NON_REACTIVE, PRIVATE
    updatemode = "webchannel"
    request_image = false

    cameras = copy(VideoIO.CAMERA_DEVICES), READONLY
    
    # refresh rate of the browser (not necessarily identical with the hardware refreshrate `camera.fps`)
    # this can be chosen a higher number than the hardware resfresh rate, e.g. 100, as the browser will skip frames
    # as long as the previous frame has not been transferred. Very high rates will decrease browser performance, though.
    fps = 0 

    img = UInt8[], PRIVATE
    image = ""
end

Stipple.js_methods(model::WebCam) = """
    updateimage: function () { 
        if (this.updatemode == "webchannel") {
            if (! this.request_image) { this.request_image = true }
        } else {
            this.image = "frame/$(hash(model.camera[]))/" + new Date().getTime()
        }
    },
    startcamera: function () { 
        if (this.fps) {
            this.cameratimer = setInterval(this.updateimage, 1000/this.fps);
        } else {
            this.updateimage()
        }
    },
    stopcamera: function () { 
        clearInterval(this.cameratimer);
    }
"""

Stipple.js_watch(model::WebCam) = """
    cameraon: function (newval, oldval) { 
        this.stopcamera()
        if (newval) { this.startcamera() }
    },

    request_image: function (newval, oldval) { 
        if (this.cameraon & this.updatemode == "webchannel" & this.fps == 0 & ! this.request_image) { 
            this.request_image = true
        }
    }
"""

function handlers(model)
    on(model.isready) do isready
        isready || return
        push!(model)
        model.cameraon[] = true
    end

    on(model.cameraon) do ison
        haskey(CAMERAS, hash(model.camera[])) || return
        camera = CAMERAS[hash(model.camera[])]
        ison ? start_camera(camera) : stop_camera(camera)
    end

    onbutton(model.request_image) do
        global t0
        model.image[] = base64png(CAMERAS[hash(model.camera[])].img)
        # println("fps: ", 1000 / (now() - t0).value)
        # t0 = now()
    end

    model
end

# for debugging:
# kill(model.cam_process__[])

function ui(model)
    page(model, [      
            p(imageview("", src=:image, no__transition=true, basic = true, style="
                -webkit-app-region: drag;
                border-radius: 50%;
                width: 95vw;
                height: 95vw"),
            style = "margin: 2.5vw"),

            p(toggle("", fieldname = :cameraon)),
    ], title = "WebCam") * 
    script("""document.documentElement.style.setProperty("--st-dashboard-bg", "#fff0")""") *
    style("""
        ::-webkit-scrollbar { width: 0px; }
        body:hover { background: #ffcccc00 }
    """)
end

# for debugging:
# ElectronAPI.reload(win)

function camerawidget()
    win = Window(URI("http://localhost:$PORT"), options = Dict(
        "transparent" => true,
        "frame" => false,
        "width" => 145,
        "height" => 200,
    ))
    
    ElectronAPI.setAlwaysOnTop(win, true)

    # initialize `oldSize`, `width` and `height`
    wsize = ElectronAPI.getSize(win)
    run(win.app, """
        oldSize = $(json(wsize))
        width = oldSize[0]
        height = oldSize[1]
    """)
    
    # implement auto resize on dragging of the side handles
    # resizing by the edge handles works only poorly
    ElectronAPI.on(win, "resize", JSONText("function() {
        win = electron.BrowserWindow.fromId($(win.id))
        newSize = win.getSize()

        if (Math.abs(oldSize[0] - newSize[0]) < 5) {
            height = newSize[1]
            width = height - 45
        } else if (Math.abs(oldSize[1] - newSize[1]) < 5) {
            width = newSize[0]
            height = width + 45
        }
        
        if (Math.abs(oldSize[0] - newSize[0]) < 3 & Math.abs(oldSize[1] - newSize[1]) < 3) {
            oldSize = newSize
            return
        }
        
        oldSize = [width, height]
        win.setSize(width, height)
    }"))
    win
end

function __init__()
    t0 = now()

    route("/") do
        init(WebCam, debounce = 0) |> handlers |> ui |> html
    end
    
    route("/requestmode") do
        model = init(WebCam, debounce = 0)
        model.updatemode[] = "requestmode"
        model.fps[] = 10
        model |> handlers |> ui |> html
    end
    
    route("frame/:camera/:timestamp") do
        # for performance measurement uncomment the following lines
        # global t0
        # println("                                                  fps: ", 1000 / (now() - t0).value)
        # t0 = now()
        cam_id = parse(UInt64, payload(:camera))
        HTTP.Messages.Response(200, CAMERAS[cam_id].img)
    end

    port = get(ENV, "CAMERA_PORT", PORT)
    up(port)

    win = camerawidget()
end

end # module