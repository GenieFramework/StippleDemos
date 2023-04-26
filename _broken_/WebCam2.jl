# Camera Widget based on VideoIO. This version is currently less performant than the FFMPEG version
# because the png compression is done by Julia whereas in the FFMPEG version
# this is done by an external process which is not competing for resources.

# Requires a webcam to be connected to the computer running this

using Stipple, StippleUI
using HTTP
using VideoIO, ImageIO, FileIO

import Base.cconvert
Base.cconvert(::Type{Ptr{Ptr{VideoIO.AVDictionary}}}, d::VideoIO.AVDict) = d.ref_ptr_dict

const img = Ref{Any}()
const IMG = Ref{Vector{UInt8}}()
const CAM_PROCESS = Ref{Task}() # a container for the camera process
const CAM = Ref{VideoIO.VideoReader}()

const FPS = 30 # some cameras only support fix values, e.g. 30
const FPS_CLIENT = 8
const Δt = 1/FPS

const PORT = 8001

function img2png(image)
    io = IOBuffer()
    save(Stream(format"PNG", io), image)
    take!(io)
end


cameraon = true

function start_camera()
    CAM[] = VideoIO.opencamera()
    CAM_PROCESS[] = @async begin
        global cameraon, FPS, i_raw, i_png
        cameraon = true
        i_raw = 0
        i_png = -1
        img[] = read(CAM[])
        while cameraon
            t0 = now()
            i_raw += 1
            read!(CAM[], img[])
            (i_raw % 300 == 0) && println("Camera image: $i_raw")
            dt = (now() - t0).value
            sleep(Δt - dt > 0 ? Δt - dt : 1/100) # minimum of 1 ms to have Julia responsive
        end
    end
end

function stop_camera()
    global cameraon
    cameraon = false
    close(CAM[])
end

# emergency break:
# Base.throwto(cameraproc, InterruptException())

@vars WebCam begin
    cameraon::R{Bool} = true
    imageurl::String = ""
    cameratimer::Int = 0
end

Stipple.js_methods(model::WebCam) = """
    updateimage: function () { 
        this.imageurl = "frame/" + new Date().getTime();
    },
    start_camera: function () { 
        console.log("start camera")
        this.cameratimer = setInterval(this.updateimage, 1000/$FPS_CLIENT);
    },
    stopcamera: function () { 
        console.log("stop camera")
        clearInterval(this.cameratimer);
    }
"""

Stipple.js_created(model::WebCam) = """
    if (this.cameraon) { this.start_camera() }
"""

Stipple.js_watch(model::WebCam) = """
    cameraon: function (newval, oldval) { 
        this.stopcamera()
        if (newval) { this.start_camera() }
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
    # conert only the frames that are needed
    global i_raw, i_png, IMG, img
    if i_png != i_raw
        IMG[] = img2png(img[])
        i_png = i_raw
    end
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