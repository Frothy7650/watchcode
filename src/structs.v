module main

import status

struct State {
mut:
	times    []i64
	failures int
	cfg      Config
	script   ?string
}

struct Config {
mut:
	// General
	url    string
	scheme status.Scheme
	loops  int  = -1
	delay  int  = 1
	tries  int  = 3
	format bool = true

	// Logging
	log_path string

	// Script
	script_path     string
	script_log_path string

	// Extra output
	print_http_body     bool
	print_script_output bool
}
