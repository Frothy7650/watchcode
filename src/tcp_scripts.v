module main

import time
import net
import os

fn run_script(mut conn net.TcpConn, script_path string, script_log_path string) ! {
	lines.clear()
	log_normal('running ${script_path}...')!
	script := os.read_file(script_path)!.split_into_lines()

	if script_log_path != '' {
		scriptlogfile = os.open_append(script_log_path)!
		is_logging = true
	}

	is_conn = true

	go fn [mut conn] () {
		for {
			if !is_conn { break
			 }
			line := conn.read_line()
			lines_mutex.lock()
			lines << line
			lines_mutex.unlock()
			if is_logging {
				scriptlogfile.write_string(line.replace('\r', '')) or {
					eprintln('Failed to write to file: ${err}')
					exit(5)
				}
				scriptlogfile.flush()
			} else {
				print(line.replace('\r', ''))
			}
		}
	}()

	for cmd in script {
		if cmd.starts_with('wait') {
			target := cmd.after('wait ')
			if target.len == 0 { return error('Invalid target in script') }
			wait_for_string(target)!
			continue
		} else if cmd.starts_with('sleep') {
			seconds_to_sleep_for := cmd.after('sleep ').int()
			if seconds_to_sleep_for == -1 { return error('Invalid script sleep command') }
			time.sleep(time.second * seconds_to_sleep_for)
			continue
		} else if cmd.starts_with('quit') {
			target := cmd.after('quit ')
			if target.len == 0 { return error('Invalid target in script') }
			wait_for_string(target)!
			return
		}
		conn.write_string(cmd + '\r\n')!
	}
	log_normal('${script_path} done!')!
	time.sleep(time.second)
}

fn wait_for_string(target string) ! {
	for {
		lines_mutex.lock()
		for line in lines {
			if line.contains(target) {
				lines_mutex.unlock()
				if scriptlogfile.is_opened { scriptlogfile.write_string('Found ${target}') or {} }
				return
			}
		}
		lines_mutex.unlock()
		time.sleep(time.millisecond * 50)
	}
}
