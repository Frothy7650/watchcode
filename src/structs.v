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
	url          string
	scheme       status.Scheme
	loops        int  = -1
	delay        int  = 1
	tries        int  = 3
	format       bool = true
	log_path     string
	script_path  string
	print_body   bool
	print_script bool
}
