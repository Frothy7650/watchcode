module main

import frothy7650.chalk
import net.http as _
import arrays
import time
import os

fn main() {
	// Setup custom sigint handler
	os.signal_opt(.int, handle_sigint) or {
		eprintln('Failed to change SIGINT handler: ${err}')
		exit(1)
	}

	// Get configuration from args
	cfg := parse_args(os.args) or {
		eprintln('Failed to parse args: ${err}')
		exit(2)
	}

	// Get output mode
	mut mode := OutputMode.stdout_plain

	if cfg.json {
		mode = .stdout_json
	}

	if cfg.cr && !cfg.json {
		mode = .stdout_cr
	}

	if cfg.log_path != '' {
		if cfg.json {
			mode = .file_json
		} else {
			mode = .file_plain
		}
	}

	// Setup logfile if needed
	if cfg.log_path != '' {
		setup_logfile(cfg.log_path) or {
			eprintln('Failed to setup logfile: ${err}')
			exit(3)
		}
	}

	cr = cfg.cr

	mut failures := 0

	for i := 0; i != cfg.loops; i++ {
		if failures == cfg.tries {
			eprintln('${cfg.scheme} request failed ${cfg.tries} times, exiting...')
			exit(4)
		}

		// Capture loop start time
		start := time.now()

		// Get status
		mut status := get_status(cfg.url, cfg.scheme, cfg.script_path, cfg.script_log_path) or {
			mut toprint := ''
			if cfg.format {
				toprint = chalk.red('${cfg.scheme} request failed: ${err}, retrying')
			} else {
				toprint = '${cfg.scheme} request failed: ${err}, retrying'
			}

			println(toprint)
			failures++
			continue
		}

		// Get time for request
		elapsed := time.since(start)
		times << elapsed.milliseconds()

		// Print url, time, and status
		log(i, status, elapsed, cfg, mode)

		delay := time.second * cfg.delay
		// Wait 1 second minus the time it took
		if elapsed < delay {
			time.sleep(delay - elapsed)
		}
	}

	print_summary(times) or {
		eprintln('Failed to print summary: ${err}')
		exit(6)
	}
	print('Done!')
}

fn handle_sigint(_ os.Signal) {
	// NOTE: If there are weird panics, it might be here
	print_summary(times) or { panic(err) }
	print('Bye!')
	exit(0)
}

fn print_summary(times []i64) ! {
	if !cr && logfile.is_opened {
		// Overwrite the current line after Ctrl+C
		println('\r-- Summary --')
	} else {
		// Normal newline behavior
		println('\n-- Summary --')
	}

	if times.len == 0 {
		println('No requests recorded.')
		return
	}

	mut average_time := i64(0)

	for t in times {
		average_time += t
	}

	average_time /= times.len

	println('Average request time: ${average_time} ms')
	println('Highest request time: ${arrays.max(times) or {
		return error('Failed to get largest in array: ${err}')
	}} ms')
	println('Lowest request time: ${arrays.min(times) or {
		return error('Failed to get smallest in array: ${err}')
	}} ms')
}
