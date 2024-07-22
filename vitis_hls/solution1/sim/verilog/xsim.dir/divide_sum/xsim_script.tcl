set_param project.enableReportConfiguration 0
load_feature core
current_fileset
xsim {divide_sum} -view {{divide_sum_dataflow_ana.wcfg}} -tclbatch {divide_sum.tcl} -protoinst {divide_sum.protoinst}
