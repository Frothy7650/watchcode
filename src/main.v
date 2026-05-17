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

  cfg := parse_args(os.args) or {
    eprintln('Failed to parse args: ${err}')
    exit(1)
  }

  cr = cfg.cr

	mut failures := 0

  for i := 0; i != cfg.loops; i++ {
    if failures == cfg.tries {
      eprintln('GET request failed ${cfg.tries} times, exiting...')
      exit(2)
    }

    // Capture loop start time
    start := time.now()

    // Get status
    mut status := '${http.get(cfg.url) or {
      mut toprint := ''
      if cfg.format {
        toprint = chalk.red('GET request failed: ${err}, retrying')
      } else {
        toprint = 'GET request failed: ${err}, retrying'
      }

      println(toprint)
      failures++
      continue
    }.status_code}'

    // Colourize status
    if cfg.format {
      if status == '200' {
        status = chalk.green(status)
      } else {
        status = chalk.red(status)
      }
    }

    // Get time for request
    elapsed := time.since(start)
    times << elapsed.milliseconds()

    // Print url, time, and status
    if cr {
      print('\r${i + 1}. ${cfg.url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
    } else {
      println('${i + 1}. ${cfg.url} at ${time.now().custom_format('HH:mm:ss')}: ${status}, GET request took ${elapsed.str()}')
    }

    delay := time.second * cfg.delay
    // Wait 1 second minus the time it took
    if elapsed < delay {
      time.sleep(delay - elapsed)
    }
  }

  print_averages(times)
  print('Done!')
}

fn handle_sigint(_ os.Signal) {
  // NOTE: If there are weird panics, it might be here
  print_averages(times)
	print('Bye!')
	exit(0)
}

fn print_averages(times []i64) {
  	mut average_time := i64(0)

	for t in times {
		average_time += t
	}

	if times.len != 0 && average_time != 0 {
		average_time /= times.len
	}

	if !cr {
		println('\nAverage request time: ${average_time} ms')
	} else {
		println('\n\rAverage request time: ${average_time} ms')
	}
}
