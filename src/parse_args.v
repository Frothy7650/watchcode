module main

import os

fn parse_args(args []string) !Config {
	mut cfg := Config{}

	// Skip executable name
	mut i := 1

	for i < args.len {
		arg := args[i]

		match arg {
			'--help' {
				println("Watches URL's status code")
				println('\t-n\tcontrol how many times the status code is checked')
				println('\t-r\tprint all logs on 1 line')
				println('\t-d\tcontrol delay between checks')
				println('\t-t\tcontrol retry count')
				println('\t-f\tdisable formatting')
				println('\t-l\tlog to a file')
				println('\t-j\toutput JSON instead of text')
				println('\t-s\trun commands on connection')
				println('\t-sl\tlog the output from script')
				exit(0)
			}
			'-r' {
				cfg.cr = true
			}
			'-f' {
				cfg.format = false
			}
			'-j' {
				cfg.json = true
			}
			'-n', '-d', '-t', '-l', '-s', '-sl' {
				// Ensure next value exists
				if i + 1 >= args.len {
					return error('missing value after ${arg}')
				}

				value := args[i + 1]

				match arg {
					'-n' {
						if !is_str_digit(value) {
							eprintln('Invalid number: ${value}')
							exit(7)
						}
						cfg.loops = value.int()
					}
					'-d' {
						if !is_str_digit(value) {
							eprintln('Invalid number: ${value}')
							exit(7)
						}

						cfg.delay = value.int()

						if cfg.delay <= 0 {
							cfg.delay = 1
						}
					}
					'-t' {
						if !is_str_digit(value) {
							eprintln('Invalid number: ${value}')
							exit(7)
						}

						cfg.tries = value.int()

						if cfg.tries <= 0 {
							cfg.tries = 1
						}
					}
					'-l' {
						cfg.log_path = os.abs_path(value)
					}
					'-s' {
						cfg.script_path = os.abs_path(value)
					}
					'-sl' {
						cfg.script_log_path = os.abs_path(value)
					}
					else {}
				}

				// Skip flag value
				i++
			}
			else {
				// URL
				if arg.starts_with('http://') || arg.starts_with('https://')
					|| arg.starts_with('tcp://') {
					cfg.url = arg
					mut scheme := Scheme.http
					arg_scheme, _ := arg.split_once(':') or {
						return error('Error splitting URL: ${err}')
					}

					match arg_scheme {
						'http' { scheme = .http }
						'https' { scheme = .http }
						'tcp' { scheme = .tcp }
						else { return error('Unknown URL scheme: ${arg_scheme}') }
					}

					cfg.scheme = scheme
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

	if cfg.json {
		cfg.cr = false
		cfg.format = false
	}

	if cfg.scheme == .http && cfg.script_path != '' {
		return error('Cannot use scripts with HTTP/s')
	}

	if cfg.script_path != '' {
		if !os.exists(cfg.script_path) {
			return error('Script not found at ${cfg.script_path}')
		}
	}

	if cfg.script_path == '' && cfg.script_log_path != '' {
		return error('Cannot log script output without a script')
	}

	if cfg.script_path != '' && cfg.script_log_path == '' {
		return error('Please provide a script log path with -sl')
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
