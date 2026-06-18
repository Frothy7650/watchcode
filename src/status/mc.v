module status

import net
import encoding.binary
import json
import time

fn write_varint(mut buf []u8, value int) {
	mut v := value

	for {
		mut temp := u8(v & 0x7F)
		v >>= 7

		if v != 0 {
			temp |= 0x80
		}

		buf << temp

		if v == 0 {
			break
		}
	}
}

fn write_string(mut buf []u8, s string) {
	write_varint(mut buf, s.len)
	buf << s.bytes()
}

fn handshake(host string, port int, protocol int) []u8 {
	mut data := []u8{}

	write_varint(mut data, 0) // packet id
	write_varint(mut data, protocol)
	write_string(mut data, host)

	mut port_bytes := []u8{len: 2}
	binary.big_endian_put_u16(mut port_bytes, u16(port))
	data << port_bytes

	write_varint(mut data, 1) // status state

	mut packet := []u8{}
	write_varint(mut packet, data.len)
	packet << data

	return packet
}

fn status_request() []u8 {
	mut data := []u8{}
	write_varint(mut data, 0)

	mut packet := []u8{}
	write_varint(mut packet, data.len)
	packet << data

	return packet
}

fn read_varint(mut conn net.TcpConn) !int {
	mut num := 0
	mut res := 0

	for {
		mut b := []u8{len: 1}
		conn.read(mut b)!
		byte := b[0]

		res |= int(u32(byte & 0x7F) << (7 * num))
		num++

		if (byte & 0x80) == 0 {
			break
		}

		if num > 5 {
			return error('VarInt too large')
		}
	}

	return res
}

fn mc(url string) !Status {
	host := url.before(':')
	port := if host.len == url.len { 25565 } else { url.after(':').int() }

	mut conn := net.dial_tcp('${host}:${port}')!

	// handshake
	hs := handshake(host, port, 760)
	conn.write(hs)!

	// status request
	req := status_request()
	conn.write(req)!

	// packet length
	_ := read_varint(mut conn)!

	// packet id
	_ := read_varint(mut conn)!

	// json length
	json_len := read_varint(mut conn)!

	mut buf := []u8{len: json_len}
	mut total := 0
	for total < json_len {
		n := conn.read(mut buf[total..])!
		total += n
	}

	conn.close()!

  status_json := json.decode(McStatus, buf.bytestr()) or {
    panic('Internal error, failed to decode mc status into JSON: ${err}')
  }

  ts := time.now().hhmmss()

  status_var := Status{
    ok: true
    msg: '${url} at ${ts}: ${status_json.players.online}/${status_json.players.max} players, version ${status_json.version.name}'
    raw: buf.bytestr()
  }

  return status_var
}

struct McStatus {
	description          string
	players              Players
	version              Version
	enforces_secure_chat bool @[json: enforcesSecureChat]
}

struct Players {
	max    int
	online int
}

struct Version {
	name     string
	protocol int
}
