module main

import status
import os

fn parse_args(args []string) !Config {
	mut cfg := Config{}

	// Skip executable name
	mut i := 1

	for i < args.len {
		arg := args[i]

		match arg {
			// TODO: update some of these
			'--help' {
				eprintln("Watches URL's status code")
				eprintln('\t-n\tcontrol how many times the status code is checked')
				eprintln('\t-d\tcontrol delay between checks')
				eprintln('\t-t\tcontrol retry count')
				eprintln('\t-f\tdisable formatting')
				eprintln('\t-l\tlog to a file')
				eprintln('\t-s\trun commands on connection')
				eprintln('\t-p\toutput the HTTP/s request body')
        eprintln('\t-ps\tprint script output')
				exit(0)
			}
			'-p' {
				cfg.print_body = true
			}
			'-f' {
				cfg.format = false
			}
      '-ps' {
        cfg.print_script = true
      }
			'-n', '-d', '-t', '-l', '-s' {
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

						if cfg.delay < 0 {
							cfg.delay = 0
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
					else {}
				}

				// Skip flag value
				i++
			}
			else {
				// URL
				if arg.starts_with('http://') || arg.starts_with('https://')
					|| arg.starts_with('tcp://') || arg.starts_with('mc://') {
					cfg.url = if arg.starts_with('http://') || arg.starts_with('https://') {
						arg
					} else {
						arg.after('://')
					}
					mut scheme := status.Scheme.http
					arg_scheme, _ := arg.split_once('://') or {
						return error('Error splitting URL: ${err}')
					}

					match arg_scheme {
						'http' { scheme = .http }
						'https' { scheme = .http }
						'tcp' { scheme = .tcp }
						'mc' { scheme = .mc }
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

	if cfg.scheme == .http && cfg.script_path != '' {
		return error('Cannot use scripts with HTTP/s, use TCP instead')
	}

	if cfg.script_path != '' {
		if !os.exists(cfg.script_path) {
			return error('Script not found at ${cfg.script_path}')
		}
	}

  if cfg.format && cfg.log_path != '' {
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
