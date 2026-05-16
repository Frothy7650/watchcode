module main

import frothy7650.chalk
import net.http
import time
import os

__global (
	times []i64
	cr    bool
)

fn main() {
	os.signal_opt(.int, handle_sigint)!

	if os.args.len < 2 {
		eprintln('Please provide at least one URL')
		exit(1)
	}

	dprintln(os.args.join(', '))

	if os.args[1] == '--help' || os.args[1] == '-h' {
		println("Watches URL's status code")
		println('\t-n\tcontrol how many times the status code is checked, e.g. watchcode -n 5 https://example.com (default: infinite)')
		println('\t-r\tprint all logs on 1 line, e.g. watchcode -r https://example.com')
		println('\t-d\tconrol the delay inbetween checks(in seconds) (default: 1)')
		print('\t-t\tcontrol how many times the GET request can fail before the program exits, (default: 3)')
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
	dprintln(loops.str())

	mut delay := time.second
	if os.args.contains('-d') {
		delay_str := os.args[os.args.index('-d') + 1]

		for ch in delay_str {
			if !is_digit(ch) {
				eprintln('Invalid loop delay: ${os.args[os.args.index('-d') + 1]}')
				return
			}
		}

		delay = time.second * delay_str.int()
	}
	dprintln(delay.str())

	mut tries := 3
	if os.args.contains('-t') {
		tries_str := os.args[os.args.index('-t') + 1]

		for ch in tries_str {
			if !is_digit(ch) {
				eprintln('Invalid retry count: ${os.args[os.args.index('-t') + 1]}')
				return
			}
		}

		tries = tries_str.int()

		if tries <= 0 {
			tries = 1
		}
	}
	dprintln(tries.str())

	if os.args.contains('-r') {
		cr = true
	}
	dprintln(cr.str())

	mut url := ''

	for i, arg in os.args {
		if i == 0 { continue
		 }

		if arg == '-n' || arg == '-r' || arg == '-d' || arg == '-t' {
			continue
		}

		if i > 1 && (os.args[i - 1] == '-n' || os.args[i - 1] == '-d' || os.args[i - 1] == '-t') {
			continue
		}

		url = arg
		break
	}

	if url == '' {
		eprintln('Please provide a URL')
		exit(1)
	}

	dprintln(url)

	mut failures := 0

	if loops == 0 {
		for {
			if failures == tries {
				eprintln('GET request failed ${tries} times, exiting...')
				exit(2)
			}

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

			times << elapsed.milliseconds()

			// Print url, time, and status
			if cr {
				print('\r${url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
			} else {
				println('${url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
			}

			// Wait 1 second minus the time it took
			if elapsed < delay {
				time.sleep(delay - elapsed)
			}
		}
	} else {
		for i := 0; i != loops; i++ {
			if failures == tries {
				eprintln('GET request failed ${tries} times, exiting...')
				exit(2)
			}

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

			times << elapsed.milliseconds()

			// Print url, time, and status
			if cr {
				print('\r${i + 1}. ${url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
			} else {
				println('${i + 1}. ${url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
			}

			// Wait 1 second minus the time it took
			if elapsed < delay {
				time.sleep(delay - elapsed)
			}
		}

		mut average_time := i64(0)

		for t in times {
			average_time += t
		}

		if times.len != 0 && average_time != 0 {
			average_time /= times.len
		}

		if cr {
			println('\nAverage request time: ${average_time} ms')
		} else {
			println('\rAverage request time: ${average_time} ms')
		}
		print('Done!')
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

fn handle_sigint(_ os.Signal) {
	mut average_time := i64(0)

	for t in times {
		average_time += t
	}

	if times.len != 0 && average_time != 0 {
		average_time /= times.len
	}

	if cr {
		println('\nAverage request time: ${average_time} ms')
	} else {
		println('\rAverage request time: ${average_time} ms')
	}
	print('Bye!')
	exit(0)
}
