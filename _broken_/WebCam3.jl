# WebCam: Camera Widget
# - uses VideoUI only for determination of camera names and format
# - camera can be deactivated to allow for access from other video software
# - images are converted to png by ffmpg.exe
# - supports two update modes: "webchannel" (default) and "url"
# - supports multiple cameras, hardware and models are separated
# - browser refresh rate (model.fps) is reflected after reactivating the camera
# - model.fps = 0 together with model.updatemode = "webchannel" will update as fast as possible
# - this is the new default, so please provide model.fps > 0 in "url" updatemode.

# Note: currently I have defined a global model in order to easily play with the values from the REPL
# in a productive application that might be removed

using Stipple, StippleUI
using HTTP
using FileIO, VideoIO
import VideoIO.FFMPEG.ffmpeg

import Base.cconvert
Base.cconvert(::Type{Ptr{Ptr{VideoIO.AVDictionary}}}, d::VideoIO.AVDict) = d.ref_ptr_dict

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
const CAMERAS = Dict{String, Camera}()

# CAMERAS = Dict(camera => Camera(;camera) for camera in VideoIO.CAMERA_DEVICES)

empty!(CAMERAS)
for camera in VideoIO.CAMERA_DEVICES
    push!(CAMERAS, camera => Camera(;camera))
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

# ffmpeg(f, cmd::Cmd; kwargs...) = ffmpeg(f ∘ (x->`$x $cmd`); kwargs...)
# ffmpeg(cmd::Cmd; kwargs...) = ffmpeg(String ∘ read, cmd; kwargs...)

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

@reactive! mutable struct WebCam <: ReactiveModel
    camera::R{String} = CAMERAS[first(VideoIO.CAMERA_DEVICES)].camera
    cameraon::R{Bool} = false
    cameratimer::Int = 0
    updatemode::R{String} = "webchannel"
    request_image::R{Bool} = false

    cameras::R{Vector{String}} = copy(VideoIO.CAMERA_DEVICES), READONLY
    
    # refresh rate of the browser (not necessarily identical with the hardware refreshrate `camera.fps`)
    # this can be chosen a higher number than the hardware resfresh rate, e.g. 100, as the browser will skip frames
    # as long as the previous frame has not been transferred. Very high rates will decrease browser performance, though.
    # There are 
    fps::R{Int} = 0 

    img::R{Vector{UInt8}} = Vector{UInt8}(), PRIVATE
    image::R{String} = ""
end

Stipple.js_methods(model::WebCam) = """
    updateimage: function () { 
        if (this.updatemode == "webchannel") {
            if (! this.request_image) { this.request_image = true }
        } else {
            this.image = "frame/" + new Date().getTime()
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

# no longer needed, now taken care of by `isready` in `handlers()`
# Stipple.js_created(model::WebCam) = """
#    if (this.cameraon) { this.startcamera() }
# """

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
        model.cameraon[] = true
    end

    on(model.cameraon) do ison
        haskey(CAMERAS, model.camera[]) || return
        camera = CAMERAS[model.camera[]]
        ison ? start_camera(camera) : stop_camera(camera)
    end

    onbutton(model.request_image) do
        global t0
        model.image[] = base64png(CAMERAS[model.camera[]].img)
        # println("fps: ", 1000 / (now() - t0).value)
        # t0 = now()
    end

    model
end

# kill(model.cam_process__[])

function ui(model)
    dashboard(model, [      
            p(quasar(:img, "", src=:image, :basic, style="
                -webkit-app-region: drag;
                border-radius: 50%;
                width: 95vw;
                height: 95vw"),
            style = "margin: 2.5vw"),

            p(toggle("", fieldname = :cameraon)),
    ], title = "WebCam") * 
    script("""document.documentElement.style.setProperty("--st-dashboard-bg", "#0000")""") *
    style("""
        ::-webkit-scrollbar { width: 0px; }
        body:hover { background: #ffcccc00 }
    """)
end

# for debugging
# ElectronAPI.reload(win)

route("/") do
    global model

    model = init(WebCam, debounce = 0)
    model |> handlers |> ui |> html
end

t0 = now()
route("frame/:timestamp") do
    global model, t0
    # println("                                                  fps: ", 1000 / (now() - t0).value)
    # t0 = now()
    HTTP.Messages.Response(200, CAMERAS[model.camera[]].img)
end

Genie.config.server_host = "127.0.0.1"

up(PORT)

using Electron, JSON

function camerawidget()
    win = Window(URI("http://localhost:$PORT"), options = Dict(
        "transparent" => true,
        "frame" => false,
        "width" => 145,
        "height" => 200,
    ))
    
    ElectronAPI.setAlwaysOnTop(win, true)
    ElectronAPI.on(win, "resize", JSON.JSONText("""function() { 
        win = electron.BrowserWindow.fromId($(win.id))
        if (win.oldBounds === undefined) { win.oldBounds = win.getBounds() }
        newBounds = win.getBounds()
        startBounds = win.getBounds()

        if (Math.abs(win.oldBounds.width - newBounds.width) < 5) {
            height = newBounds.height
            width = height - 45
        } else if (Math.abs(win.oldBounds.height - newBounds.height) < 5) {
            width = newBounds.width
            height = width + 45
        }
        
        if (Math.abs(win.oldBounds.width - width) < 3 & Math.abs(win.oldBounds.height - height) < 3) {
            console.log('not resized')
            win.oldBounds = startBounds
            return
        }
        
        newBounds.width = width
        newBounds.height = height

        win.oldBounds = newBounds
        win.setBounds(newBounds)
    }"""))
    win
end

win = camerawidget()