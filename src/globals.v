module main

import os

__global (
	times   []i64
	cr      bool
	logfile os.File
  scriptlogfile os.File
  lines   []string
  is_conn bool
)
