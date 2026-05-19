module main

import time
import net
import os

fn run_script(mut conn net.TcpConn, script_path string, script_log_path string) ! {
	println('running ${script_path}...')
	script := os.read_file(script_path)!.split_into_lines()
	scriptlogfile = os.open_append(script_log_path)!
	is_conn = true

		go fn [mut conn, script_log_path] () {
		for {
			if !is_conn { break
			 }
			line := conn.read_line()
			lines_mutex.lock()
			lines << line
			lines_mutex.unlock()
			if script_log_path != '' {
				scriptlogfile.write_string(line.replace('\r', '')) or {
					eprintln('Failed to write to file: ${err}')
					exit(5)
				}
				scriptlogfile.flush()
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
		println(cmd)
	}
	println('${script_path} done!')
	time.sleep(time.second)
}

fn wait_for_string(target string) ! {
	for {
		lines_mutex.lock()
		for line in lines {
			if line.contains(target) {
				lines_mutex.unlock()
				println('Found ${target}')
				return
			}
		}
		lines_mutex.unlock()
    time.sleep(time.millisecond * 50)
	}
}
