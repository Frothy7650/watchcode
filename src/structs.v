module main

import time

struct JsonLog {
	i         int
	url       string
	scheme    Scheme
	timestamp string
	status    string
	elapsed   time.Duration
}

struct Config {
mut:
	url             string
	scheme          Scheme
	loops           int = -1
	delay           int = 1
	tries           int = 3
	cr              bool
	format          bool = true
	json            bool
	log_path        string
	script_path     string
	script_log_path string
}

struct McStatus {
	description          string
	players              Players
	version              Version
	enforces_secure_chat bool @[json: enforcesSecureChat]
}

struct Players {
	max    int
	online int
}

struct Version {
	name     string
	protocol int
}

enum Scheme {
	http
	tcp
	mc
}
