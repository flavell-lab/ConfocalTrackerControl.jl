macro daqmx_check(exp)
    error_code = eval(exp)
    if error_code != 0
        error("DAQmx error $error_code")
    end
    
    nothing
end

empty_str = ""
ptr_empty_str = pointer(empty_str)

function nidaq_configure()
    # tasks creation
    # analog: laser (488 nm analog), stim for opto (AO))
    global task_ai = analog_input("$NIDAQ_DEV_NAME/ai0, $NIDAQ_DEV_NAME/ai1, $NIDAQ_DEV_NAME/_ao1_vs_aognd",
        terminal_config=NIDAQ.Differential, range=[0,10])
    # digital: confocal camera AUX 1 OUT, behavior camera
    global task_di = digital_input("$NIDAQ_DEV_NAME/port0/line0:1")

    # configure sample clocks
    # AI
    NIDAQ.DAQmxCfgSampClkTiming(task_ai.th, ptr_empty_str, NIDAQ_SAMPLE_RATE_AI, NIDAQ.DAQmx_Val_Rising,
        NIDAQ.DAQmx_Val_ContSamps, 100 * NIDAQ_SAMPLE_RATE_AI)
    # DI
    NIDAQ.DAQmxCfgSampClkTiming(task_di.th, "ai/SampleClock", NIDAQ_SAMPLE_RATE_AI, NIDAQ.DAQmx_Val_Rising,
        NIDAQ.DAQmx_Val_ContSamps, 100 * NIDAQ_SAMPLE_RATE_AI)
end