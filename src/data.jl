Base.@kwdef mutable struct Param
    # tracking
    θ_net::Float64 = 0.9
    Δ_move_min = 3 # pixels
    Δ_move_max = 125 # pixels
    Δ_offset = 15 # pixels
    
    # display color
    c_nose_on::UInt32 = 0xff1f77b4
    c_nose_off::UInt32 = 0xcc195f90
    c_mid_on::UInt32 = 0xffff7f0e
    c_mid_off::UInt32 = 0xcccc660b
    c_pharynx_on::UInt32 = 0xff2ca02c
    c_pharnyx_off::UInt32 = 0xcc2ca02c
    c_offset::UInt32 = 0xffd62728
end

Base.@kwdef mutable struct SessionData
    # loops
    q_loop::Bool = true
    q_recording::Bool = false
    n_loop::Int = 0
    t_recording_start::Int = 0

    # image
    img_array::Array{UInt8,2} = zeros(UInt8, IMG_SIZE_X, IMG_SIZE_Y)
    
    # tracking
    q_tracking::Bool = false
    
    # display
    q_show_net::Bool = true
    q_show_ruler::Bool = false
    q_show_crosshair::Bool = true

    # stage
    x_stage::Float64 = 0
    y_stage::Float64 = 0
    
    # recording
    list_pos_net = []
    list_pos_stage::Array{Array{Float64,1},1} = []
    list_img::Array{Array{UInt8,2},1} = []
    
    # daq
    list_ai_read = []
    list_di_read = []
    
    # speed cb
    speed_cb = CircularBuffer{ValWithTime{Float64}}(ceil(Int,
            1/LOOP_INTERVAL_SAVE_STAGE ^ -1))
end

function reset!(session::SessionData)
    session.q_loop = true
    session.q_recording = false
    session.n_loop = 0
    session.img_array .= 0
    session.x_stage = 0
    session.y_stage = 0
    
    session.list_pos_net = []
    session.list_pos_stage = []
    session.list_img = []
    
    session.list_ai_read = []
    session.list_di_read = []
end

function reset_recording!(session::SessionData)
    session.n_loop = 0    
    session.list_pos_net = []
    session.list_pos_stage = []
    session.list_img = []
    session.list_ai_read = []
    session.list_di_read = []
end

struct ValWithTime{T}
    val::T
    t::UInt64
    
    ValWithTime(val::T, t::UInt64) where {T} = new{T}(val, t)
    ValWithTime(val::T) where {T} = new{T}(val, time_ns())
end

function save_h5(path_h5)
    @assert(splitext(path_h5)[end] == ".h5")
    @assert(!isfile(path_h5))
    
    n_t = length(session.list_pos_stage)
    stage_ = zeros(Float64, 2, n_t)
    feature_ = zeros(Float32, 3,3,n_t)
    img_ = zeros(UInt8, IMG_SIZE_X, IMG_SIZE_Y, n_t)
    
    for t = 1:n_t
        stage_[:,t] .= session.list_pos_stage[t]
        feature_[:,:,t] .= session.list_pos_net[t]
        img_[:,:,t] .= session.list_img[t]
    end
        
    h5open(path_h5, "cw") do h5f
        h5f["img_nir", chunk=(IMG_SIZE_X, IMG_SIZE_Y, 1), blosc=9] = round.(UInt8, img_)
        attributes(h5f["img_nir"])["desc"] = "850 nm NIR image"
        
        write(h5f, "pos_feature", feature_)
        write(h5f, "pos_stage", stage_)
    end
    
    nothing
end