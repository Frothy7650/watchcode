module main

import frothy7650.chalk
import time
import json
import os

fn log(i int, status string, elapsed time.Duration, cfg Config, mode OutputMode) {
	mut text_status, is_error_status := get_status_text(status, cfg.scheme)
	ts := time.now().custom_format('HH:mm:ss')
	json_data := JsonLog{
		i:         i
		url:       cfg.url
		scheme:    cfg.scheme
		timestamp: ts
		status:    status
		elapsed:   elapsed
	}

	mut status_str := '${status}'

	if cfg.format {
		if is_error_status {
			status_str = chalk.red(status_str)
			text_status = chalk.red(text_status)
		} else {
			status_str = chalk.green(status_str)
			text_status = chalk.green(text_status)
		}
	}

	log := '${i + 1}. ${cfg.url} at ${json_data.timestamp}: ${if cfg.scheme == .http {
		status_str
	} else {
		'\b'
	}} ${text_status}, ${cfg.scheme} took ${elapsed.str()}'

	match mode {
		.stdout_json {
			println(json.encode(json_data))
		}
		.file_json {
			logfile.writeln(json.encode(json_data)) or { eprintln(err) }
			logfile.flush()
		}
		.stdout_cr {
			print('\r${log}')
		}
		.stdout_plain {
			println(log)
		}
		.file_plain {
			logfile.writeln(log) or {
				eprintln('Failed to write to file: ${err}')
				exit(5)
			}
			logfile.flush()
		}
	}
}

enum OutputMode {
	stdout_plain
	stdout_cr
	stdout_json
	file_plain
	file_json
}

fn setup_logfile(path string) ! {
	if os.exists(path) {
		os.rm(path) or { return error('Failed to remove ${path}: ${err}') }
	}

	os.create(path) or { return error('Failed to create ${path}: ${err}') }

	logfile = os.open_append(path) or {
		return error('Failed to open ${path} in append mode: ${err}')
	}
}

fn get_status_text(status_code string, scheme Scheme) (string, bool) {
	match scheme {
		.http {
			match status_code {
				'200' { return 'OK', false }
				'404' { return 'FILE NOT FOUND', true }
				'502' { return 'INTERNAL SERVER ERROR', true }
				else { return 'UNKNOWN', false }
			}
		}
		.tcp {
			match status_code {
				'online' { return 'ONLINE', false }
				'conn refused' { return 'CONNECTION REFUSED', true }
				else { return 'UNKNOWN: ${status_code}', true }
			}
		}
	}

	panic('Well this should never happen')
}
