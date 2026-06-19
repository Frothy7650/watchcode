module main

import frothy7650.chalk
import status
import arrays
import time
import os

__global (
	state State
)

fn main() {
	// Setup custom sigint handler
	os.signal_opt(.int, handle_sigint) or {
		eprintln('Failed to change SIGINT handler: ${err}')
		exit(1)
	}

	// Get configuration and state
	state = State{
		cfg: parse_args(os.args) or {
			eprintln('Failed to parse args: ${err}')
			exit(2)
		}
	}

	state.script = if state.cfg.script_path != '' {
		os.read_file(state.cfg.script_path)!
	} else {
		none
	}

	if state.cfg.log_path != '' {
		persist_stderr_to_disk(state.cfg.log_path)
		if state.cfg.script_log_path != '' {
			persist_stdout_to_disk(state.cfg.script_log_path)
		} else {
			redirect_stdout_to_stderr()
		}
	} else {
		redirect_stderr_to_stdout()
		if state.cfg.script_log_path != '' {
			persist_stdout_to_disk(state.cfg.script_log_path)
		}
	}

	for i := 0; i != state.cfg.loops; i++ {
		if state.failures == state.cfg.tries {
			eprintln('${state.cfg.scheme} request failed ${state.cfg.tries} times, exiting...')
			exit(4)
		}

		// Capture loop start time
		start := time.now()

		// Get status
		mut status_var := status.get_status(state.cfg.url, state.cfg.scheme, state.script,
			state.cfg.format, state.cfg.print_script_output) or {
			mut toprint := ''
			if state.cfg.format {
				toprint = chalk.red('${state.cfg.scheme} request failed: ${err}, retrying')
			} else {
				toprint = '${state.cfg.scheme} request failed: ${err}, retrying'
			}

			eprintln(toprint)
			state.failures++
			continue
		}

		// Get time for request
		elapsed := time.since(start)
		state.times << elapsed.milliseconds()

		// Print body if user wants it
		if state.cfg.print_http_body && status_var.meta['body'] != '' {
			eprintln('>>> START')
			eprintln(status_var.meta['body'])
			eprintln('>>> END')
		}

		// Print url, time, and status
		eprintln('${i + 1}. ${status_var.msg}, ${elapsed}')

		delay := time.second * state.cfg.delay
		// Wait 1 second minus the time it took
		if elapsed < delay {
			time.sleep(delay - elapsed)
		}
	}

	print_summary() or {
		eprintln('Failed to print summary: ${err}')
		exit(6)
	}
}

fn handle_sigint(_ os.Signal) {
	// NOTE: If there are weird panics, it might be here
	print_summary() or { panic(err) }
	print('done')
	exit(0)
}

fn print_summary() ! {
	eprintln('\n-- Summary --')

	if state.times.len == 0 {
		eprintln('No requests recorded.')
		return
	}

	mut average_time := i64(0)

	for t in state.times {
		average_time += t
	}

	average_time /= state.times.len

	eprintln('Average request time: ${average_time} ms')
	eprintln('Highest request time: ${arrays.max(state.times) or {
		return error('Failed to get largest in array: ${err}')
	}} ms')

	eprintln('Lowest request time: ${arrays.min(state.times) or {
		return error('Failed to get smallest in array: ${err}')
	}} ms')
}
