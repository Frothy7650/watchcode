module status

import time
import net

fn run_script(mut conn net.TcpConn, script_raw string, print_script bool) !string {
  println('script_start')
	mut raw_buf := []u8{}
	mut lines := []string{}
	mut eof := false

	conn.set_read_timeout(1 * time.millisecond)
	script := script_raw.split_into_lines()

	for cmd in script {
		if !eof {
			eof = drain_data(mut conn, mut raw_buf, mut lines, print_script)
		}
		if cmd.starts_with('#') { continue }
		if cmd.starts_with('wait for') {
			target := cmd.after('wait for ')
			if target.len == 0 { return error('Invalid target in script') }
			wait_for_string(target, mut conn, mut raw_buf, mut lines, print_script, eof) or { return err }
			continue
		}
		if cmd.starts_with('sleep') {
			sleep_str := cmd.after('sleep ')
			if !sleep_str.is_int() { return error('Invalid script sleep command') }
			seconds := sleep_str.int()
			time.sleep(time.second * seconds)
			continue
		}
		if cmd.starts_with('quit on') {
			target := cmd.after('quit on ')
			if target.len == 0 { return error('Invalid target in script') }
			wait_for_string(target, mut conn, mut raw_buf, mut lines, print_script, eof) or { return err }
			return lines.join_lines()
		}
		if cmd.starts_with('if ') {
			target_and_code := cmd.after('if ').split_nth(' ', 2)
			if target_and_code.len < 2 { return error('Invalid if syntax') }
			target := target_and_code[0]
			code := target_and_code[1]
			for line in lines {
				if line.contains(target) {
					if print_script { println('Found ${target}, running ${code}') }
					run_script(mut conn, code, print_script)!
					break
				}
			}
			continue
		}
		conn.write_string(cmd + '\r\n')!
	}
	if !eof {
		for _ in 0..120 {
			eof = drain_data(mut conn, mut raw_buf, mut lines, print_script)
			if eof { break }
			time.sleep(time.millisecond * 50)
		}
	}
  println('script_end')
	return lines.join_lines()
}

fn drain_data(mut conn net.TcpConn, mut raw_buf []u8, mut lines []string, print_script bool) bool {
	for {
		mut buf := []u8{len: 4096}
		n := conn.read(mut buf) or { break }
		if n == 0 { return true }
		raw_buf << buf[..n]
		process_raw_buf(mut raw_buf, mut lines, print_script)
	}
	return false
}

fn process_raw_buf(mut raw_buf []u8, mut lines []string, print_script bool) {
	mut start := 0
	for i, b in raw_buf {
		if b == `\n` {
			line := raw_buf[start..i].bytestr().trim_right('\r')
			if line.len > 0 {
				lines << line
				if print_script { println(line) }
			}
			start = i + 1
		}
	}
	if start > 0 {
		unsafe { raw_buf = raw_buf[start..] }
	}
}

fn wait_for_string(target string, mut conn net.TcpConn, mut raw_buf []u8, mut lines []string, print_script bool, eof bool) ! {
	mut targets := []string{}
	mut local_eof := eof
	if target.contains('||') {
		targets = target.split('||')
		for i, t in targets {
			targets[i] = t.trim_space()
		}
	} else {
		targets << target
	}
	for {
		if !local_eof {
			local_eof = drain_data(mut conn, mut raw_buf, mut lines, print_script)
		}
		for line in lines {
			for t in targets {
				if line.contains(t) {
					if print_script { println('Found ${t}, continuing') }
					return
				}
			}
		}
		if local_eof { return error('connection closed before ${target} was found') }
		time.sleep(time.millisecond * 50)
	}
}
