set SynModuleInfo {
  {SRCNAME divide_sum MODELNAME divide_sum RTLNAME divide_sum IS_TOP 1
    SUBMODULES {
      {MODELNAME divide_sum_sdiv_32ns_32ns_32_36_1 RTLNAME divide_sum_sdiv_32ns_32ns_32_36_1 BINDTYPE op TYPE sdiv IMPL auto LATENCY 35 ALLOW_PRAGMA 1}
      {MODELNAME divide_sum_flow_control_loop_pipe RTLNAME divide_sum_flow_control_loop_pipe BINDTYPE interface TYPE internal_upc_flow_control INSTNAME divide_sum_flow_control_loop_pipe_U}
    }
  }
}
