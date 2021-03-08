# ConfocalTrackerControl.jl
## Instructions
### GUI
Loading the package automatically initializes the components (camera, stage controller, neural net, etc.). To launch the GUI:
```julia
using QML, ConfocalTrackerControl
@async loop_main()
```

The main control loop can be stopped by:
```julia
ConfocalControl.session.session.q_loop = false
```
After stopping, the loop can be restarted by executing ```@async loop_main()```. To restart the loop after closing the GUI window, restart the kernel.

### Saving data
Executing ```save_h5(path_h5)``` writes the current recording buffer to the provided path. The HDF5 file contains the following:  
`img_nir`: 850 nm images (sampling rate: 20 fps)  
`pos_feature`: output of the neural network (sampling rate: 20 fps)  
`pos_stage`: x/y stage location in the stage unit (10000 stage unit / 1 mm) (sampling rate: 20 fps)  

### Parameters
It is recommended to use the **default parameters**. If you'd like to change any, adjust the parameters before calling the main loop. Otherwise, you need to stop and restart the main loop.  

**WARNING**: improper paramter changes could cause stage instability or runaway, which could potentailly damange the stage.

User adjustable parameters:  
`θ_net::Float64=0.9`: threshold for the neural net output confidence. For iterations with below `θ_net`, the tracker doesn't update the velocity.  
`Δ_move_min=3`: [pixels] min displacement. If the displacement is below this, the tracker doesn't update the velocity. Supressing noise.  
`Δ_move_max=125`: [pixels] max displacement. If the displacement is above this, the tracker doesn't update the velocity. Supressing false positive.  
`Δ_offset=15`: [pixels] offset on where to center the stage along the metacorpus-pharynx axis. Number of pixels distance from the metacorpus.  
