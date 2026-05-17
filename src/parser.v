module main

import os

struct Config {
mut:
	url      string
	loops    int = -1
	delay    int = 1
	tries    int = 3
	cr       bool
	format   bool = true
	log_path string
}

fn parse_args(args []string) !Config {
	mut cfg := Config{}

	// Skip executable name
	mut i := 1

	for i < args.len {
		arg := args[i]

		match arg {
			'-h', '--help' {
				println("Watches URL's status code")
				println('\t-n\tcontrol how many times the status code is checked')
				println('\t-r\tprint all logs on 1 line')
				println('\t-d\tcontrol delay between checks')
				println('\t-t\tcontrol retry count')
				println('\t-f\tdisable formatting')
				println('\t-l\tlog to a file')
				exit(0)
			}
			'-r' {
				cfg.cr = true
			}
			'-f' {
				cfg.format = false
			}
			'-n', '-d', '-t', '-l' {
				// Ensure next value exists
				if i + 1 >= args.len {
					return error('missing value after ${arg}')
				}

				value := args[i + 1]

				match arg {
					'-n' {
            if !is_str_digit(value) {
              eprintln('Invalid number: ${value}')
              exit(1)
            }
						cfg.loops = value.int()
					}
					'-d' {
            if !is_str_digit(value) {
              eprintln('Invalid number: ${value}')
              exit(1)
            }

						cfg.delay = value.int()

						if cfg.delay <= 0 {
							cfg.delay = 1
						}
					}
					'-t' {
            if !is_str_digit(value) {
              eprintln('Invalid number: ${value}')
              exit(1)
            }

						cfg.tries = value.int()

						if cfg.tries <= 0 {
							cfg.tries = 1
						}
					}
					'-l' {
						cfg.log_path = os.abs_path(value)
						persist_stdout_to_disk(cfg.log_path)
					}
					else {}
				}

				// Skip flag value
				i++
			}
			else {
				// URL
				if arg.starts_with('http://') || arg.starts_with('https://') {
					cfg.url = arg
				} else {
					return error('unknown argument: ${arg}')
				}
			}
		}

		i++
	}

	if cfg.url == '' {
		return error('missing URL')
	}

	if cfg.log_path != '' {
		cfg.cr = false
		cfg.format = false
	}

	return cfg
}

fn is_digit(c u8) bool {
	return c >= u8(48) && c <= u8(57)
}

fn is_str_digit(s string) bool {
  for c in s {
    if !is_digit(c) { return false }
  }
  return true
}
