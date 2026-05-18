module main

import time

struct JsonLog {
	i           int
	url         string
	timestamp   string
	status_text string
	status_code int
	elapsed     time.Duration
}

struct Config {
mut:
	url      string
	loops    int = -1
	delay    int = 1
	tries    int = 3
	cr       bool
	format   bool = true
	json     bool
	log_path string
}
