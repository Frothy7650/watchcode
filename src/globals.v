module main

import os
import sync

__global (
	times         []i64
	cr            bool
	logfile       os.File
	scriptlogfile os.File
	lines         []string
	is_conn       bool
	lines_mutex   sync.Mutex
)
