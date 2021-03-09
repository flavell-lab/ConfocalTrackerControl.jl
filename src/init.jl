const py_tf = PyNULL()
const py_pid = PyNULL()
const py_dlc = PyNULL()

ENV["QSG_RENDER_LOOP"] = "basic"

function __init__()
   
    # data
    global canvas_buffer = zeros(UInt32, 968 * 732)
    global param = Param()
    global session = SessionData()

    # gui
    start_gui()
    
    # py
    copy!(py_tf, pyimport("tensorflow"))
    copy!(py_dlc, pyimport("dlclive"))
    copy!(py_pid, pyimport("simple_pid"))
 
    
    # stage
    global sp_stage = LibSerialPort.open(DEFAULT_PORT, SERIAL_BAUD_RATE)
    check_baud_rate(sp_stage)
    
    # camera
    camlist = CameraList()
    global cam = camlist[0]
    
    Spinnaker.set!(Spinnaker.SpinFloatNode(cam, "AcquisitionFrameRate"),
        Float64(LOOP_INTERVAL_CONTROL))
    @assert(isapprox(Float64(LOOP_INTERVAL_CONTROL), framerate(cam), rtol=0.05))
    
    triggermode!(cam, "Off")
    start!(cam)
    imid, imtimestamp = getimage!(cam, session.img_array, normalize=false)
    stop!(cam)
    
    buffermode!(cam, "NewestOnly")
    buffercount!(cam, 3)
    
    # neural net
    tf_config = config = py_tf.ConfigProto()
    tf_config.gpu_options.allow_growth = true

    global dlc = py_dlc.DLCLive(PATH_MODEL, pcutoff=0.75, tf_config=tf_config)

    start!(cam)
    imid, imtimestamp = getimage!(cam, session.img_array, normalize=false)
    dlc.init_inference(session.img_array[IMG_CROP_RG_X, IMG_CROP_RG_Y])
    stop!(cam)
    
    # PID
    global pid_x = py_pid.PID(PID_X_P, PID_X_I, PID_X_D, setpoint=0.)
    global pid_y = py_pid.PID(PID_Y_P, PID_Y_I, PID_Y_D, setpoint=0.)
    pid_x.output_limit = (-15000, 15000)
    pid_y.output_limit = (-15000, 15000)
    pid_x.setpoint = Float64.(0)
    pid_y.setpoint = Float64.(0)
    
    nothing
end