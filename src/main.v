module main

import frothy7650.chalk
import net.http
import time
import os

fn main() {
	if os.args.len < 2 {
		eprintln('Please provide at least one URL')
		exit(1)
	}

	if os.args[1] == '--help' || os.args[1] == '-h' {
		println("Watches URL's status code")
		println('\t-n\tcontrol how many times the status code is checked, e.g. watchcode -n 5 https://example.com')
		println('\t-r\tprint all logs on 1 line, e.g. watchcode -r https://example.com')
		return
	}

	mut loops := 0
	if os.args.contains('-n') {
		loops_str := os.args[os.args.index('-n') + 1]

		for ch in loops_str {
			if !is_digit(ch) {
				eprintln('Invalid loop count: ${os.args[os.args.index('-n') + 1]}')
				return
			}
		}

		loops = loops_str.int()
	}

	mut cr := false
	if os.args.contains('-r') {
		cr = true
	}

	mut url := ''

	for i, arg in os.args {
		if i == 0 { continue
		 }

		if arg == '-n' || arg == '-r' {
			continue
		}

		if i > 1 && os.args[i - 1] == '-n' {
			continue
		}

		url = arg
		break
	}

	if url == '' {
		eprintln('Please provide a URL')
		exit(1)
	}

	mut failures := 0

	if loops == 0 {
		for {
			// Capture loop start time
			start := time.now()

			// Get status
			mut status := '${http.get(url) or {
				println(chalk.red('GET request failed: ${err}, retrying'))
				failures++
				continue
			}.status_code}'

			// Colourize status
			if status == '200' {
				status = chalk.green(status)
			} else {
				status = chalk.red(status)
			}

			// Get time for request
			elapsed := time.since(start)

			// Print url, time, and status
			if cr {
				print('\r${url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
			} else {
				println('${url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
			}

			// Wait 1 second minus the time it took
			dprintln(elapsed.str())
			if elapsed < time.second {
				time.sleep(time.second - elapsed)
			}
		}
	} else {
		for i := 0; i != loops; i++ {
			// Capture loop start time
			start := time.now()

			// Get status
			mut status := '${http.get(url) or {
				println(chalk.red('GET request failed: ${err}, retrying'))
				failures++
				continue
			}.status_code}'

			// Colourize status
			if status == '200' {
				status = chalk.green(status)
			} else {
				status = chalk.red(status)
			}

			// Get time for request
			elapsed := time.since(start)

			// Print url, time, and status
			if cr {
				print('\r${i + 1}. ${url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
			} else {
				println('${i + 1}. ${url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
			}

			// Wait 1 second minus the time it took
			dprintln(elapsed.str())
			if elapsed < time.second {
				time.sleep(time.second - elapsed)
			}
		}
		if cr {
			print('\nDone!')
		} else {
			print('Done!')
		}
	}
}

fn is_digit(c u8) bool {
	return c >= u8(48) && c <= u8(57)
}

fn dprintln(s string) {
	$if debug {
		println(s)
	}
}
